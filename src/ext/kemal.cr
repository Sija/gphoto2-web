LAST_MODIFIED_HEADER_NAME   = "Last-Modified"
LAST_MODIFIED_HEADER_FORMAT = "%a, %d %b %Y %H:%M:%S GMT"

def send_file(env, file : GPhoto2::CameraFile, mime_type : String? = nil)
  filename = nil

  # WARNING: Executes extra calls to underlying camera
  if file.preview?
    filename = GPhoto2::CameraFile::PREVIEW_FILENAME
    mime_type ||= "image/jpeg"
  else
    filename = file.name
    info = file.info.file
    if mtime = info.mtime
      env.response.headers[LAST_MODIFIED_HEADER_NAME] = \
         mtime.to_s(LAST_MODIFIED_HEADER_FORMAT)
    end
    mime_type ||= info.type
  end

  send_file env, file.to_slice, mime_type,
    filename: filename,
    disposition: "inline"
end

def send_folder_zip(env, folder : GPhoto2::CameraFolder, archive_name : String? = nil)
  archive_name ||= folder.root? ? folder.@camera.model.gsub(/\s+/, '-') : folder.name

  folder.to_zip_file(archive_name) do |file|
    send_file env, file.path, "application/zip",
      filename: "#{archive_name}.zip"
  end
end

def send_json(env, object) : Nil
  object.to_json env.response
    .tap &.content_type = "application/json"
end

def send_204(env) : Nil
  env.response.status_code = 204
end
