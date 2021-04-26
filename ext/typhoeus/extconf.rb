ENV['RC_ARCHS'] = '' if RUBY_PLATFORM =~ /darwin/

# :stopdoc:

require 'mkmf'

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
specified_curl = ARGV[0] =~ /^--with-curl/ ? ARGV[0].split("=")[1] : nil
LIBDIR = specified_curl ? "#{specified_curl}/lib": RbConfig::CONFIG['libdir']
INCLUDEDIR = specified_curl ? "#{specified_curl}/include" : RbConfig::CONFIG['includedir']

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'macruby'
  $LIBRUBYARG_STATIC.gsub!(/-static/, '')
end

$CFLAGS << " #{ENV["CFLAGS"]}"
if RbConfig::CONFIG['target_os'] == 'mingw32'
  $CFLAGS << " -DXP_WIN -DXP_WIN32 -DUSE_INCLUDED_VASPRINTF"
elsif RbConfig::CONFIG['target_os'] == 'solaris2'
  $CFLAGS << " -DUSE_INCLUDED_VASPRINTF"
else
  $CFLAGS << " -g -DXP_UNIX"
end

#$LIBPATH.unshift "/opt/local/lib"
#$LIBPATH.unshift "/usr/local/lib"

$CFLAGS << " -O3 -Wall -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline"

found = pkg_config("libcurl") && have_header("curl/curl.h")

if RbConfig::CONFIG['target_os'] == 'mingw32'
  header = File.join(ROOT, 'cross', 'curl-7.19.4.win32', 'include')
  unless find_header('curl/curl.h', header)
    abort "need libcurl"
  end
elsif !found
  HEADER_DIRS = [
    INCLUDEDIR,
    '/usr/local/include',
    '/usr/include'
  ]

  puts HEADER_DIRS.inspect
  unless find_header('curl/curl.h', *HEADER_DIRS)
    abort "need libcurl"
  end
end

if RbConfig::CONFIG['target_os'] == 'mingw32'
  find_library('curl', 'curl_easy_init',
               File.join(ROOT, 'cross', 'curl-7.19.4.win32', 'bin'))
elsif !found
  find_library('curl', 'curl_easy_init', LIBDIR, '/usr/local/lib', '/usr/lib')
end

create_makefile("xingfus/native")
