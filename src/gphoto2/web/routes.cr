get "/cameras" do |env|
  send_json env, GPhoto2::Web.cameras.map(&.camera)
end

get "/cameras/reload" do |env|
  GPhoto2::Web.reset_cameras
  GPhoto2::Web.cameras
  env.redirect "/cameras"
end

get "/cameras/:id" do |env|
  id = env.params.url["id"]
  camera = GPhoto2::Web.camera_by_id(id)

  send_json env, camera
end

get "/cameras/:id/exit" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    camera.exit
  end
  env.redirect "/cameras"
end

get "/cameras/:id/config" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    config = if env.params.query["flat"]? == "true"
               camera.config
             else
               camera.window
             end
    send_json env, config
  end
end

post "/cameras/:id/config" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    camera.update(env.params.json)
  end
  send_204 env
end

get "/cameras/:id/config/:widget" do |env|
  id = env.params.url["id"]
  widget = env.params.url["widget"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    send_json env, camera.config[widget]
  end
end

post "/cameras/:id/config/:widget" do |env|
  id = env.params.url["id"]
  widget = env.params.url["widget"]
  value = env.params.json["value"].as(String)

  GPhoto2::Web.camera_by_id(id) do |camera|
    camera.update({widget => value})
  end
  send_204 env
end

get "/cameras/:id/fs" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    send_json env, camera.filesystem
  end
end

def zip_visitor(zip, folder : GPhoto2::CameraFolder, root : String? = nil)
  folder.files.each do |file|
    pathname = root ? File.join(root, file.path) : file.path
    pathname = pathname[1..-1] if pathname.starts_with? '/'
    mtime = file.info.try(&.file.mtime) || Time.now
    entry = Zip::Writer::Entry.new pathname, time: mtime

    zip.add entry, file.to_slice
  end
  folder.folders.each do |child|
    zip_visitor(zip, child, root)
  end
end

get "/cameras/:id/fs.zip" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera.filesystem

    archive_name = camera.model.gsub(/\s+/, '-')
    archive_filename = "%s.zip" % archive_name

    tempfile = File.tempfile(prefix: "camera.fs", suffix: ".zip") do |file|
      Zip::Writer.open(file) do |zip|
        zip_visitor zip, fs, archive_name
      end
    end

    send_file env, tempfile.path, "application/zip",
      filename: archive_filename

    tempfile.delete
  end
end

get "/cameras/:id/fs/*filepath" do |env|
  id = env.params.url["id"]
  filepath = env.params.url["filepath"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera.filesystem File.dirname(filepath)
    file = fs.open File.basename(filepath)

    send_file env, file
  end
end

delete "/cameras/:id/fs/*filepath" do |env|
  id = env.params.url["id"]
  filepath = env.params.url["filepath"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera.filesystem File.dirname(filepath)
    file = fs.open File.basename(filepath)

    file.delete
  end
  send_204 env
end

get "/cameras/:id/capture" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    file = camera.capture

    send_file env, file
  end
end

get "/cameras/:id/preview" do |env|
  id = env.params.url["id"]

  # NOTE: might be good to use queue here
  GPhoto2::Web.camera_by_id(id) do |camera|
    file = camera.preview

    send_file env, file
  end
end
