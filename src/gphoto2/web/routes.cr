# /cameras

get "/cameras" do |env|
  reload = env.params.query["reload"]? == "true"
  GPhoto2::Web.reset_cameras if reload

  cameras = GPhoto2::Web.cameras.map(&.camera)
  send_json env, cameras
end

# /cameras/:id

get "/cameras/:id" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    send_json env, camera
  end
end

get "/cameras/:id/capture" do |env|
  id = env.params.url["id"]
  delete = env.params.query["delete"]? == "true"

  GPhoto2::Web.camera_by_id(id) do |camera|
    file = camera.capture
    send_file(env, file).tap do
      file.delete if delete
    end
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

get "/cameras/:id/exit" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    camera.exit
  end
  send_204 env
end

# /cameras/:id/config

get "/cameras/:id/config" do |env|
  id = env.params.url["id"]
  flat = env.params.query["flat"]? == "true"

  GPhoto2::Web.camera_by_id(id) do |camera|
    config = flat ? camera.config : camera.window
    send_json env, config
  end
end

patch "/cameras/:id/config" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    camera.update(env.params.json)
  end
  send_204 env
end

# /cameras/:id/config/:widget

get "/cameras/:id/config/:widget" do |env|
  id = env.params.url["id"]
  widget = env.params.url["widget"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    config = camera.config[widget]
    send_json env, config
  end
end

patch "/cameras/:id/config/:widget" do |env|
  id = env.params.url["id"]
  widget = env.params.url["widget"]
  value = env.params.json["value"].as(String)

  GPhoto2::Web.camera_by_id(id) do |camera|
    camera.update({widget => value})
  end
  send_204 env
end

# /cameras/:id/fs

get "/cameras/:id/fs" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera.filesystem
    send_json env, fs
  end
end

get "/cameras/:id/fs/*path" do |env|
  id = env.params.url["id"]
  path = env.params.url["path"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera / path
    send_json env, fs
  end
end

delete "/cameras/:id/fs/*path" do |env|
  id = env.params.url["id"]
  path = env.params.url["path"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera / path
    fs.delete
  end
  send_204 env
end

# /cameras/:id/blob

get "/cameras/:id/blob/*filepath" do |env|
  id = env.params.url["id"]
  filepath = env.params.url["filepath"]
  path = Path.posix(filepath)

  width = env.params.query["width"]?.try(&.to_i)
  height = env.params.query["height"]?.try(&.to_i)

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera / path.dirname
    file = fs.open(path.basename)

    if width
      send_file env, file,
        width: width,
        height: height
    else
      send_file env, file
    end
  end
end

delete "/cameras/:id/blob/*filepath" do |env|
  id = env.params.url["id"]
  filepath = env.params.url["filepath"]
  path = Path.posix(filepath)

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera / path.dirname
    file = fs.open(path.basename)
    file.delete
  end
  send_204 env
end

# /cameras/:id/zip

get "/cameras/:id/zip" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera.filesystem
    send_folder_zip env, fs,
      archive_name: camera.model
  end
end

get "/cameras/:id/zip/*path" do |env|
  id = env.params.url["id"]
  path = env.params.url["path"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera / path
    send_folder_zip env, fs
  end
end

# Error pages

error 404 do |env|
  if request_accepts_json?(env.request)
    send_json env, {error: "Not found"}
  else
    render_404
  end
end

error 500 do |env, err|
  if request_accepts_json?(env.request)
    send_json env, {error: err.to_s}
  else
    render_500(env, err, true)
    nil
  end
end
