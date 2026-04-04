module ApplicationHelper
  # Marks the sidebar link as active based on current controller
  def active_link?(controller_name_check)
    controller_name == controller_name_check ||
      (controller_name_check == "dashboard" && controller_name == "dashboard")
  end

  # Returns Tailwind color classes for a given color name
  def status_bg(color)
    {
      "emerald" => "bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200",
      "amber"   => "bg-amber-50 text-amber-700 ring-1 ring-amber-200",
      "red"     => "bg-red-50 text-red-700 ring-1 ring-red-200",
      "gray"    => "bg-slate-100 text-slate-700 ring-1 ring-slate-200",
      "blue"    => "bg-blue-50 text-blue-700 ring-1 ring-blue-200",
      "sky"     => "bg-sky-50 text-sky-700 ring-1 ring-sky-200",
      "slate"   => "bg-slate-100 text-slate-700 ring-1 ring-slate-200"
    }[color.to_s] || "bg-slate-100 text-slate-700 ring-1 ring-slate-200"
  end

  def dot_color(color)
    {
      "emerald" => "bg-emerald-500",
      "amber"   => "bg-amber-500",
      "red"     => "bg-red-500",
      "gray"    => "bg-slate-500",
      "blue"    => "bg-blue-500",
      "sky"     => "bg-sky-500",
      "slate"   => "bg-slate-500"
    }[color.to_s] || "bg-slate-500"
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

  def nav_link_classes(key)
    active = active_link?(key)
    base = "flex items-center gap-3 rounded-xl px-3 py-2 text-sm transition-colors"
    active ? "#{base} bg-[#eaf2ff] text-[#124170] font-semibold" : "#{base} text-slate-600 hover:bg-slate-100 hover:text-slate-900"
  end
end
