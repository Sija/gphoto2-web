# /cameras

get "/cameras" do |env|
  reload = env.params.query["reload"]? == "true"
  GPhoto2::Web.reset_cameras if reload

  GPhoto2::Web.cameras do |cameras|
    send_json env, cameras
  end
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
    send_file(env, file, format: :auto).tap do
      file.delete if delete
    end
  end
end

get "/cameras/:id/preview" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    send_file env, camera.preview
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
    send_json env, flat ? camera.config : camera.window
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
    send_json env, camera.config[widget]
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
    send_json env, camera.filesystem
  end
end

get "/cameras/:id/fs/*path" do |env|
  id = env.params.url["id"]
  path = env.params.url["path"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    send_json env, camera / path
  end
end

delete "/cameras/:id/fs/*path" do |env|
  id = env.params.url["id"]
  path = env.params.url["path"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    camera
      .filesystem(path)
      .delete
  end
  send_204 env
end

put "/cameras/:id/fs/*path" do |env|
  id = env.params.url["id"]
  path = env.params.url["path"]
  path = Path.posix("/", path)

  GPhoto2::Web.camera_by_id(id) do |camera|
    folder = camera
      .filesystem(path.dirname)
      .mkdir(path.basename)

    send_json env, folder
  end
end

# /cameras/:id/blob

get "/cameras/:id/blob/*filepath" do |env|
  id = env.params.url["id"]
  filepath = env.params.url["filepath"]

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
    file = camera.blob(filepath)

    env.response.headers["Vary"] = "Accept"

    if request_accepts_json?(env.request)
      send_json env, file
    else
      if format || width || height
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

  GPhoto2::Web.camera_by_id(id) do |camera|
    camera
      .blob(filepath)
      .delete
  end
  send_204 env
end

put "/cameras/:id/blob/*filepath" do |env|
  id = env.params.url["id"]
  filepath = env.params.url["filepath"]
  filepath = Path.posix("/", filepath)

  upload = env.params.files["file"]? || raise ArgumentError.new("Missing file")
  data = upload.tempfile.getb_to_end

  mime_type =
    upload.headers["Content-Type"]? ||
      MIME.from_filename?(upload.filename || filepath.basename)

  GPhoto2::Web.camera_by_id(id) do |camera|
    file = camera
      .filesystem(filepath.dirname)
      .put(filepath.basename, data,
        mime_type: mime_type,
        mtime: upload.modification_time,
      )

    env.response.headers["Vary"] = "Accept"

    if request_accepts_json?(env.request)
      send_json env, file
    else
      send_204 env
    end
  end
end

# /cameras/:id/zip

get "/cameras/:id/zip" do |env|
  id = env.params.url["id"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    send_folder_zip env, camera.filesystem,
      archive_name: camera.model
  end
end

get "/cameras/:id/zip/*path" do |env|
  id = env.params.url["id"]
  path = env.params.url["path"]

  GPhoto2::Web.camera_by_id(id) do |camera|
    send_folder_zip env, camera / path
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
    send_html env, Kemal::ExceptionPage.new(env, err)
  end
end
