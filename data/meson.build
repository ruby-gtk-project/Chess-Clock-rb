desktop_file = i18n.merge_file(
        input: 'eu.fortysixandtwo.chessclock.desktop.in',
       output: 'eu.fortysixandtwo.chessclock.desktop',
         type: 'desktop',
       po_dir: '../po',
      install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
  test('Validate desktop file', desktop_utils, args: [desktop_file])
endif

appstream_file = i18n.merge_file(
        input: 'eu.fortysixandtwo.chessclock.metainfo.xml.in',
       output: 'eu.fortysixandtwo.chessclock.metainfo.xml',
       po_dir: '../po',
      install: true,
  install_dir: join_paths(get_option('datadir'), 'metainfo')
)

appstreamcli = find_program('appstreamcli', required: false)
if appstreamcli.found()
  test('Validate appstream file', appstreamcli, args: ['validate', '--no-net', appstream_file])
endif

install_data('eu.fortysixandtwo.chessclock.gschema.xml',
  install_dir: join_paths(get_option('datadir'), 'glib-2.0/schemas')
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  test('Validate schema file',
       compile_schemas,
       args: ['--strict', '--dry-run', meson.current_source_dir()])
endif

service_conf = configuration_data()
service_conf.set('bindir', join_paths(get_option('prefix'), get_option('bindir')))
configure_file(
          input: 'eu.fortysixandtwo.chessclock.service.in',
         output: 'eu.fortysixandtwo.chessclock.service',
  configuration: service_conf,
    install_dir: join_paths(get_option('datadir'), 'dbus-1/services')
)

subdir('icons')
