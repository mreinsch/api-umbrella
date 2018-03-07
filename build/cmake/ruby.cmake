# Ruby & Bundler: For Rails web-app component
list(APPEND RUBY_CONFIGURE_CMD env)
list(APPEND RUBY_CONFIGURE_CMD <SOURCE_DIR>/configure)
list(APPEND RUBY_CONFIGURE_CMD --prefix=${INSTALL_PREFIX_EMBEDDED})
list(APPEND RUBY_CONFIGURE_CMD --enable-load-relative)
list(APPEND RUBY_CONFIGURE_CMD --disable-rpath)
list(APPEND RUBY_CONFIGURE_CMD --disable-install-doc)

ExternalProject_Add(
  ruby
  URL https://cache.ruby-lang.org/pub/ruby/ruby-${RUBY_VERSION}.tar.bz2
  URL_HASH SHA256=${RUBY_HASH}
  CONFIGURE_COMMAND rm -rf <BINARY_DIR> && mkdir -p <BINARY_DIR> # Clean across version upgrades
    COMMAND ${RUBY_CONFIGURE_CMD}
  INSTALL_COMMAND make install DESTDIR=${STAGE_DIR}
)

ExternalProject_Add(
  rubygems
  DEPENDS ruby
  URL https://rubygems.org/downloads/rubygems-update-${RUBYGEMS_VERSION}.gem
  URL_HASH SHA256=${RUBYGEMS_HASH}
  DOWNLOAD_NO_EXTRACT 1
  CONFIGURE_COMMAND ""
  BUILD_COMMAND ""
  INSTALL_COMMAND env PATH=${STAGE_EMBEDDED_DIR}/bin:$ENV{PATH} gem update --system ${RUBYGEMS_VERSION} --no-document
    COMMAND sed -i "s%^#\!${STAGE_DIR}.*/ruby$%#\!/usr/bin/env ruby%g" ${STAGE_EMBEDDED_DIR}/bin/bundle ${STAGE_EMBEDDED_DIR}/bin/gem ${STAGE_EMBEDDED_DIR}/bin/rake ${STAGE_EMBEDDED_DIR}/bin/update_rubygems
)
