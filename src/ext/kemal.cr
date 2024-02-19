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

private BROWSER_SAFE_EXTENSIONS = %w(.jpg .jpeg .png .gif .bmp .svg .webp)

def send_file(env, file : GPhoto2::CameraFile, mime_type : String? = nil, disposition = nil)
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

    ext = Path[filename].extension.downcase
    disposition ||= "inline" if ext.in?(BROWSER_SAFE_EXTENSIONS)

    send_file env, file.to_slice,
      mime_type: mime_type,
      filename: filename,
      disposition: disposition
  end
end

private MAGICKLOAD_EXTENSIONS = %w(.arw .cin .cr2 .crw .nef .orf .raf .x3f)

def send_file(env, file : GPhoto2::CameraFile, width : Int, height : Int? = nil, disposition = "inline")
  if Path[file.name].extension.downcase.in?(MAGICKLOAD_EXTENSIONS)
    image, _ = Vips::Image.magickload_buffer(file.to_slice)
  else
    image = Vips::Image.new_from_buffer(file.to_slice)
  end

  image = image.thumbnail_image(
    width: width,
    height: height,
    size: Vips::Enums::Size::Down
  )

  restore_headers_on_rescue(env.response) do |response|
    if info = file.info.file?
      if mtime = info.mtime
        response.headers["Last-Modified"] =
          mtime.to_s("%a, %d %b %Y %H:%M:%S GMT")
      end
    end

    send_file env, image.jpegsave_buffer(strip: true),
      mime_type: "image/jpeg",
      # filename: "#{Path[file.name].stem}.jpg",
      filename: file.name,
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
