def restore_headers_on_exception(response, &)
  prev_headers = response.headers.clone
  begin
    yield response
  rescue ex
    response.headers.clear
    prev_headers.each do |key, value|
      response.headers[key] = value
    end
    raise ex
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
  request.headers["Accept"]?.try &.split(',', remove_empty: true) do |accepts|
    accepts = accepts.strip
    if idx = accepts.index(';')
      accepts = accepts[...idx]
    end
    if accepts.compare(content_type, case_insensitive: true).zero?
      return true
    end
  end
  false
end

def request_accepts_json?(request)
  request_accepts?(request, "application/json")
end
