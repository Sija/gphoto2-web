private def restore_headers_on_exception(response, &)
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
  restore_headers_on_exception(env.response) do |response|
    if file.preview?
      filename = GPhoto2::CameraFile::PREVIEW_FILENAME
      mime_type ||= "image/jpeg"
    else
      filename = file.name
      # WARNING: Executes extra calls to underlying camera
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

enum ImageOutputFormat
  JPEG
  WEBP
  PNG

  def self.from_path?(path : Path)
    case path.extension.downcase
    when ".jpeg", ".jpg" then JPEG
    when ".webp"         then WEBP
    when ".png"          then PNG
    end
  end

  def extension
    case self
    in JPEG then ".jpg"
    in WEBP then ".webp"
    in PNG  then ".png"
    end
  end

  def mime_type
    case self
    in JPEG then "image/jpeg"
    in WEBP then "image/webp"
    in PNG  then "image/png"
    end
  end

  def to_slice(image : Vips::Image, **options)
    case self
    in JPEG then image.jpegsave_buffer(**options)
    in WEBP then image.webpsave_buffer(**options)
    in PNG  then image.pngsave_buffer(**options)
    end
  end
end

def send_file_as(env, file : GPhoto2::CameraFile, format : ImageOutputFormat = :jpeg, width : Int? = nil, height : Int? = nil, disposition = nil)
  path = Path[file.path]
  ext = path.extension.downcase

  same_type = (format.extension == ext)
  if same_type && !(width || height)
    send_file env, file,
      disposition: disposition
    return
  end

  if ext.in?(MAGICKLOAD_EXTENSIONS)
    image, _ = Vips::Image.magickload_buffer(file.to_slice)
  else
    image = Vips::Image.new_from_buffer(file.to_slice)
  end

  if width
    image = image.thumbnail_image(
      width: width,
      height: height,
      size: Vips::Enums::Size::Down,
    )
  end

  restore_headers_on_exception(env.response) do |response|
    if info = file.info.file?
      if mtime = info.mtime
        response.headers["Last-Modified"] =
          mtime.to_s("%a, %d %b %Y %H:%M:%S GMT")
      end
    end

    disposition ||= "inline"

    send_file env, format.to_slice(image),
      mime_type: format.mime_type,
      filename: "#{path.stem}#{format.extension}",
      disposition: disposition
  end
end

def send_folder_zip(env, folder : GPhoto2::CameraFolder, archive_name : String? = nil) : Nil
  archive_name ||= folder.name

  restore_headers_on_exception(env.response) do
    folder.to_zip_file(archive_name) do |file|
      send_file env, file.path,
        mime_type: "application/zip",
        filename: "#{archive_name}.zip"
    end
  end
end

def send_json(env, object) : Nil
  restore_headers_on_exception(env.response) do |response|
    response.content_type = "application/json"
    response << object.to_json
  end
end

def send_html(env, object) : Nil
  restore_headers_on_exception(env.response) do |response|
    response.content_type = "text/html; charset=utf-8"
    response << object.to_s
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
