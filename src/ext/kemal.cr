CONTENT_DISPOSITION_HEADER_NAME = "Content-Disposition"
LAST_MODIFIED_HEADER_NAME       = "Last-Modified"
LAST_MODIFIED_HEADER_FORMAT     = "%a, %d %b %Y %H:%M:%S GMT"

def send_file(env, file : GPhoto2::CameraFile, mime_type : String? = nil)
  # WARNING: Executes extra calls to underlying camera
  if file.preview?
    env.response.headers[CONTENT_DISPOSITION_HEADER_NAME] = \
      %(inline; filename="#{GPhoto2::CameraFile::PREVIEW_FILENAME}")
    mime_type ||= "image/jpeg"
  else
    info = file.info.file
    env.response.headers[CONTENT_DISPOSITION_HEADER_NAME] = \
      %(inline; filename="#{file.name}")
    if mtime = info.mtime
      env.response.headers[LAST_MODIFIED_HEADER_NAME] = \
        mtime.to_s(LAST_MODIFIED_HEADER_FORMAT)
    end
    mime_type ||= info.type
  end
  send_file env, file.to_slice, mime_type
end

def send_json(env, object)
  object.to_json.tap do
    env.response.content_type = "application/json"
  end
end

def send_204(env)
  env.response.status_code = 204
  nil
end
