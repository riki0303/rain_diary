module DiariesHelper
  WEATHER_ICONS = {
    "Rain"    => "bi-cloud-rain",
    "Drizzle" => "bi-cloud-drizzle",
    "Clouds"  => "bi-cloud",
    "Clear"   => "bi-sun",
    "Snow"    => "bi-snow"
  }.freeze

  def mood_dots(mood)
    filled = mood.to_i
    empty  = 5 - filled
    safe_join([
      safe_join(Array.new(filled) { tag.i(class: "bi bi-circle-fill text-warning") }),
      safe_join(Array.new(empty)  { tag.i(class: "bi bi-circle text-secondary") })
    ])
  end

  def weather_icon_class(weather_main)
    WEATHER_ICONS.fetch(weather_main, "bi-cloud")
  end

  def weather_icon_tag(weather_main, extra_class: nil)
    classes = [ "bi", weather_icon_class(weather_main), extra_class ].compact.join(" ")
    tag.i(class: classes)
  end
end
