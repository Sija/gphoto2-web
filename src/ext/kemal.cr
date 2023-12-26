private def restore_headers_on_rescue(response, &)
  prev_headers = response.headers.clone
  begin
    yield response
  rescue ex
    diff_keys = response.headers.keys - prev_headers.keys
    diff_keys.each do |key|
      response.headers.delete(key)
    end
    prev_headers.each do |key, value|
      response.headers[key] = value
    end
    raise ex
  end
end

def send_file(env, file : GPhoto2::CameraFile, mime_type : String? = nil, disposition : String? = nil)
  disposition ||= "inline"

  restore_headers_on_rescue(env.response) do |response|
    # WARNING: Executes extra calls to underlying camera
    if file.preview?
      filename = GPhoto2::CameraFile::PREVIEW_FILENAME
      mime_type ||= "image/jpeg"
    else
      filename = file.name
      if info = file.info.file?
        if mtime = info.mtime
          response.headers["Last-Modified"] =
            mtime.to_s("%a, %d %b %Y %H:%M:%S GMT")
        end
        mime_type ||= info.type
      end
    end

    send_file env, file.to_slice,
      mime_type: mime_type,
      filename: filename,
      disposition: disposition
  end
end

def send_folder_zip(env, folder : GPhoto2::CameraFolder, archive_name : String? = nil) : Nil
  archive_name ||= folder.name

  restore_headers_on_rescue(env.response) do
    folder.to_zip_file(archive_name) do |file|
      send_file env, file.path,
        mime_type: "application/zip",
        filename: "#{archive_name}.zip"
    end
  end
end

def send_json(env, object) : Nil
  restore_headers_on_rescue(env.response) do |response|
    response.content_type = "application/json"
    response << object.to_json
  end
end

def send_204(env) : Nil
  env.response.status = :no_content
end

def request_accepts?(request, content_type)
  accepts = request.headers["Accept"]?.try do |value|
    value
      .split(',')
      .map(&.strip.sub(/;.*$/, ""))
  end
  !!accepts.try &.includes?(content_type)
end

def request_accepts_json?(request)
  request_accepts?(request, "application/json")
end
