# Image BNC opener by 26000
# https://github.com/26000/imagebnc

# TODO: handle multiple images per message
require 'uri'

$config = {
  "count" => 20,
  "viewer" => "/usr/bin/feh",
  "proxy" => "http://localhost:8080/bnc",
  "pass" => "p455vv0rd",
  "timeout" => 10000
}
$links = {}

CONFIG_DESC = {
  "count" => "amount of urls stored for each buffer",
  "viewer" => "path to your image viewer (it should be able to fetch URLs)",
  "proxy" => "your proxy address (with port and path) (empty to disable)",
  "pass" => "your proxy password",
  "timeout" => "time after which the image viewer process gets killed, 0 to disable"
}
SCRIPT_NAME = "image_bnc"
REGEXP = %r{(https?://(?:[a-z0-9\-]+\.)+[a-z]{2,6}(?:\:\d{1,5})?(?:/[^ /#?]+)+\.(?:jpg|gif|png|bmp|tiff|jpeg|webp|JPG|GIF|PNG|BMP|TIFF|JPEG|WEBP))}

def i_cb data, buffer, args
  buffer = Weechat.current_buffer
  buf_number = Weechat.buffer_get_integer buffer, "number"
  link_number = args[0].to_i - 1

  if args.length < 1
    Weechat.print "", "Need one argument."
    return Weechat::WEECHAT_RC_ERROR
  end
  if $links[buf_number].nil?
    Weechat.print "", "No image links found."
    return Weechat::WEECHAT_RC_ERROR
  end
  if $links[buf_number].length <= link_number
    Weechat.print "", "No image link with index #{link_number + 1}."
    return Weechat::WEECHAT_RC_ERROR
  end

  link = $links[buf_number][link_number]
  if $config['proxy'] != ""
    url = $config['proxy'] + "?" + URI.encode_www_form("pass" => $config['pass'], "file" => link)
  else
    url = link
  end

  Weechat.hook_process("#{$config['viewer']} '#{url}'", $config['timeout'], "", "")
  return Weechat::WEECHAT_RC_OK
end

def print_cb data, buffer, date, tags, displayed, highlight, prefix, message
  m = REGEXP.match message
  return Weechat::WEECHAT_RC_OK if m.nil?
  buf_number = Weechat.buffer_get_integer buffer, "number"
  if $links[buf_number].nil?
    $links[buf_number] = m.captures.reverse
  else
    $links[buf_number] = m.captures + $links[buf_number]
    if $links[buf_number].length > $config['count']
      $links[buf_number] = $links[buf_number][0..$config['count']]
    end
  end
  return Weechat::WEECHAT_RC_OK
end

def config_cb data, option, value
  case option.split('.')[-1]
  when 'count'
    $config[option.split('.')[-1]] = value.to_i
  when 'timeout'
    $config[option.split('.')[-1]] = value.to_i
  else
    $config[option.split('.')[-1]] = value
  end
  return Weechat::WEECHAT_RC_OK
end

def weechat_init
  Weechat.register("image_bnc", "26000", "1.0", "BSD", "opens images using a proxy (or not) and also a feh (or not)", "", "")

  $config.each do |k, v|
    if Weechat.config_is_set_plugin(k) == 0
      Weechat.config_set_plugin(k, v.to_s)
    else
      case k
      when 'count'
        $config[k] = Weechat.config_get_plugin(k).to_i
      when 'timeout'
        $config[k] = Weechat.config_get_plugin(k).to_i
      else
        $config[k] = Weechat.config_get_plugin(k)
      end
    end
  end

  version = Weechat.info_get("version_number", "").to_i || 0
  if version >= 0x00030500
    CONFIG_DESC.each do |k, v|
      Weechat.config_set_desc_plugin(k, v)
    end
  end

  Weechat.hook_command("i", "open an image",
                       "<index>",
                       "<index>: the image url number counting from bottom",
                       "",
                       "i_cb", "")
  Weechat.hook_config("plugins.var.ruby." + SCRIPT_NAME + ".*", "config_cb", "")
  Weechat.hook_print("", "notify_message", "", 1, "print_cb", "")
  Weechat.hook_print("", "notify_private", "", 1, "print_cb", "")
  return Weechat::WEECHAT_RC_OK
end

