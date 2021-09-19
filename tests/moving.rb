require_relative '../termpaint'

def textbox
  b = TermPaint::TextBox.new(0, 1, 15, 10, id: :box, background_color: :green, border_color: :blue)
  b.text = "Hello! This is a textbox test.\nPlease edit this text if you want to :^)"
  b
end

def long_textbox
  b = TermPaint::TextBox.new(5, 8, 20, 9, id: :long, background_color: :white, text_color: :black)
  b.text = "This is some long text right here. I'm not sure what to type here so I'm just going to keep going!\n" * 10
  b
end

def root
  @root ||= TermPaint::Root.new
end

root << textbox
root << long_textbox
root.repaint
root.trap
box = root.find_by_id(:box)
long = root.find_by_id(:long)
Thread.new do
  400.times do |t|
    long.x = (Math.sin(t.to_f / 20).abs * (root.width - long.width - 1)).to_i
    root.repaint
    sleep 0.1
  end
end
Thread.new do
  loop do
    long.scroll_y += 1
    sleep 0.3
  end
end

50.times do |t|
  box.text = "Width: #{root.width}\nHeight: #{root.height}\nTime: #{t}"
  sleep 1
end
print TTY::Cursor.move_to(10, 20)
