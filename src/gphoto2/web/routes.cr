get "/cameras" do |env|
  cameras = GPhoto2::Web.cameras.map(&.camera)
  send_json env, cameras
end

post "/cameras/reload" do |env|
  GPhoto2::Web.reset_cameras
  GPhoto2::Web.cameras
  send_204 env
end

get "/cameras/:id" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    send_json env, camera
  end
end

post "/cameras/:id/exit" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    camera.exit
  end
  send_204 env
end

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
    fs = camera.filesystem path
    send_json env, fs
  end
end

delete "/cameras/:id/fs/*path" do |env|
  id = env.params.url["id"]
  path = env.params.url["path"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera.filesystem path
    fs.delete
  end
  send_204 env
end

get "/cameras/:id/blob/*filepath" do |env|
  id = env.params.url["id"]
  filepath = env.params.url["filepath"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera.filesystem File.dirname(filepath)
    file = fs.open File.basename(filepath)
    send_file env, file
  end
end

delete "/cameras/:id/blob/*filepath" do |env|
  id = env.params.url["id"]
  filepath = env.params.url["filepath"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera.filesystem File.dirname(filepath)
    file = fs.open File.basename(filepath)
    file.delete
  end
  send_204 env
end

get "/cameras/:id/zip" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera.filesystem
    send_folder_zip env, fs
  end
end

get "/cameras/:id/zip/*path" do |env|
  id = env.params.url["id"]
  path = env.params.url["path"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera.filesystem path
    send_folder_zip env, fs
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
