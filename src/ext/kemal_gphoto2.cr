require "./kemal"

private BROWSER_SAFE_EXTENSIONS = %w(.jpg .jpeg .png .gif .bmp .svg .webp .avif)
private MAGICKLOAD_EXTENSIONS   = %w(.arw .cin .cr2 .crw .nef .orf .raf .x3f)

enum ImageOutputFormat
  # largest in size, yet quickest in terms of encoding speed
  JPEG
  # ~half size of JPEG, 3rd to last in terms of encoding speed
  WEBP
  # smallest in size, yet slowest in terms of encoding speed
  AVIF
  # worst quality, 2nd to last in terms of encoding speed
  PNG
  # placeholder type
  AUTO

  # Returns first of *formats* found to be supported by the *request*,
  # `nil` otherwise.
  def self.from_request?(request : HTTP::Request, formats : Enumerable(self)) : self?
    formats.find do |format|
      request_accepts?(request, format.mime_type)
    end
  end

  # :ditto:
  def self.from_request?(request : HTTP::Request, *formats : self) : self?
    from_request?(request, formats)
  end

  # Returns format based on a file extension from the given *path*,
  # `nil` otherwise.
  def self.from_path?(path : Path) : self?
    ext = path.extension.downcase
    each do |format|
      return format if !format.auto? && format.extensions.includes?(ext)
    end
  end

  def extensions
    case self
    in JPEG then {".jpg", ".jpeg"}
    in WEBP then {".webp"}
    in AVIF then {".avif"}
    in PNG  then {".png"}
    in AUTO then raise "Use specific format"
    end
  end

  def extension : String
    extensions.first
  end

  def mime_type : String
    case self
    in JPEG then "image/jpeg"
    in WEBP then "image/webp"
    in AVIF then "image/avif"
    in PNG  then "image/png"
    in AUTO then raise "Use specific format"
    end
  end

  # Returns *image* in a `self` format.
  def to_slice(image : Vips::Image, **options) : Bytes
    case self
    in JPEG then image.jpegsave_buffer(**options)
    in WEBP then image.webpsave_buffer(**options)
    in PNG  then image.pngsave_buffer(**options)
    in AVIF
      Vips::Target.new_to_memory
        .tap do |target|
          image.write_to_target(target, "%.avif", **options)
        end
        .blob
    in AUTO then raise "Use specific format"
    end
  end
end

def send_file(env, file : GPhoto2::CameraFile, *, mime_type : String? = nil, disposition = nil)
  restore_headers_on_exception(env.response) do |response|
    if file.preview?
      mime_type ||= "image/jpeg"
    else
      # WARNING: Executes extra calls to underlying camera
      if info = file.info.file?
        if mtime = info.mtime
          response.headers["Last-Modified"] = HTTP.format_time(mtime)
        end
        mime_type ||= info.type
      end
    end

    ext = file.path.extension.downcase
    disposition ||= "inline" if ext.in?(BROWSER_SAFE_EXTENSIONS)

    send_file env, file.to_slice,
      mime_type: mime_type,
      filename: file.name,
      disposition: disposition
  end
end

# ameba:disable Metrics/CyclomaticComplexity
def send_file(env, file : GPhoto2::CameraFile, *, format : ImageOutputFormat?, fallback : ImageOutputFormat = :jpeg, width : Int? = nil, height : Int? = nil, disposition = nil)
  path = file.path
  path_format = ImageOutputFormat.from_path?(path)

  ext = path.extension.downcase

  if format.nil? || format.auto?
    send_if_same_size = ext.in?(BROWSER_SAFE_EXTENSIONS)
    format = path_format || fallback
  end

  is_same_format = (format == path_format)
  is_same_size = !(width || height)

  if is_same_size && (send_if_same_size || is_same_format)
    send_file env, file,
      disposition: disposition
    return
  end

  if ext.in?(MAGICKLOAD_EXTENSIONS)
    image, _ = Vips::Image.magickload_buffer(file.to_slice)
  else
    image = Vips::Image.new_from_buffer(file.to_slice)
  end

  unless is_same_size
    image = image.thumbnail_image(
      width: width || image.width,
      height: height,
      size: Vips::Enums::Size::Down,
    )
  end

  restore_headers_on_exception(env.response) do |response|
    # WARNING: Executes extra calls to underlying camera
    if info = file.info.file?
      if mtime = info.mtime
        response.headers["Last-Modified"] = HTTP.format_time(mtime)
      end
    end

    filename = String.build do |str|
      str << path.stem
      str << "-w#{width}" if width
      str << "-h#{height}" if height
      str <<
        case
        when is_same_format
          path.extension
        when path.extension.chars.select!(&.letter?).all?(&.uppercase?)
          format.extension.upcase
        else
          format.extension
        end
    end
    disposition ||= "inline"

    send_file env, format.to_slice(image),
      mime_type: format.mime_type,
      filename: filename,
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
