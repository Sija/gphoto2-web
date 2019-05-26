# FIXME: See CameraWidget::Button
struct Proc
  def to_json(json : JSON::Builder)
    to_s.to_json(json)
  end
end
