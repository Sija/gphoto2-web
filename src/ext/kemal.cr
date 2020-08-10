def send_file(env, file : GPhoto2::CameraFile, mime_type : String? = nil, disposition : String? = nil)
  disposition ||= "inline"

  # WARNING: Executes extra calls to underlying camera
  if file.preview?
    filename = GPhoto2::CameraFile::PREVIEW_FILENAME
    mime_type ||= "image/jpeg"
  else
    filename = file.name
    if info = file.info.file?
      if mtime = info.mtime
        env.response.headers["Last-Modified"] =
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

def send_folder_zip(env, folder : GPhoto2::CameraFolder, archive_name : String? = nil) : Nil
  archive_name ||= folder.name

  env.response
    .tap(&.content_type = "application/zip")
    .tap(&.headers["Content-Disposition"] = \
       %(attachment; filename="#{archive_name}.zip"))

  folder.to_zip_file(env.response, archive_name)
end

def send_json(env, object) : Nil
  env.response.content_type = "application/json"
  object.to_json(env.response)
end

def send_204(env) : Nil
  env.response.status = :no_content
end
