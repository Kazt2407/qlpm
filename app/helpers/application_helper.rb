module ApplicationHelper
  # Marks the sidebar link as active based on current controller
  def active_link?(controller_name_check)
    controller_name == controller_name_check ||
      (controller_name_check == "dashboard" && controller_name == "dashboard")
  end

  # Returns Tailwind color classes for a given color name
  def status_bg(color)
    {
      "emerald" => "bg-emerald-400/10 text-emerald-400",
      "amber"   => "bg-amber-400/10 text-amber-400",
      "red"     => "bg-red-400/10 text-red-400",
      "gray"    => "bg-gray-400/10 text-gray-400",
      "blue"    => "bg-blue-400/10 text-blue-400"
    }[color.to_s] || "bg-gray-400/10 text-gray-400"
  end

  def dot_color(color)
    {
      "emerald" => "bg-emerald-400",
      "amber"   => "bg-amber-400",
      "red"     => "bg-red-400",
      "gray"    => "bg-gray-400"
    }[color.to_s] || "bg-gray-400"
  end

  # Render a status badge span
  def status_badge(label, color)
    content_tag(:span, class: "#{status_bg(color)} text-xs px-2 py-0.5 rounded-full inline-flex items-center gap-1") do
      content_tag(:span, "", class: "w-1.5 h-1.5 rounded-full #{dot_color(color)}") + label
    end
  end

  # Format a date in Vietnamese style
  def vn_date(date)
    return "–" unless date
    date.strftime("%d/%m/%Y")
  end

  def vn_datetime(dt)
    return "–" unless dt
    dt.strftime("%d/%m/%Y %H:%M")
  end

  # Percentage bar width clamped 0–100
  def pct_width(value, total)
    return "0%" if total.zero?
    "#{[(value.to_f / total * 100).round, 100].min}%"
  end
end
