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
  value = env.params.json["value"]

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

  query_params = env.params.query

  if format = query_params["format"]?.presence
    format = ImageOutputFormat.parse?(format) || raise ArgumentError.new \
      "Format must be one of: #{ImageOutputFormat.values.join(", ", &.to_s.underscore)}"
  end

  if width = query_params["width"]?.presence
    width = width.to_i? || raise ArgumentError.new("Width must be an integer")
    width.positive? || raise ArgumentError.new("Width must be positive")
  end
  if height = query_params["height"]?.presence
    height = height.to_i? || raise ArgumentError.new("Height must be an integer")
    height.positive? || raise ArgumentError.new("Height must be positive")
  end

  download = query_params["download"]? == "true"
  disposition = "attachment" if download

  GPhoto2::Web.camera_by_id(id) do |camera|
    fs = camera / path.dirname
    file = fs.open(path.basename)

    env.response.headers["Vary"] = "Accept"

    if request_accepts_json?(env.request)
      send_json env, file
    else
      if format || width
        format ||=
          ImageOutputFormat.from_path?(path) ||
            ImageOutputFormat::JPEG

        send_file env, file,
          format: format,
          width: width,
          height: height,
          disposition: disposition
      else
        send_file env, file,
          disposition: disposition
      end
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
  env.response.headers["Vary"] = "Accept"

  if request_accepts_json?(env.request)
    send_json env, {error: "Not found"}
  else
    render_404
  end
end

error 500 do |env, err|
  if err.message.try &.matches? /not found/i
    env.response.status = :not_found
  else
    env.response.status = :internal_server_error
  end

  env.response.headers["Vary"] = "Accept"

  if request_accepts_json?(env.request)
    send_json env, {error: err.to_s}
  else
    send_html env, Kemal::ExceptionPage.for_runtime_exception(env, err)
  end
end
