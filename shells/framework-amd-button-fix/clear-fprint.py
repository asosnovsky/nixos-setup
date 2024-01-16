#! /usr/bin/python3

import gi
gi.require_version('FPrint', '2.0')
from gi.repository import FPrint

ctx = FPrint.Context()

for dev in ctx.get_devices():
    print(dev)
    print(dev.get_driver())
    print(dev.props.device_id);

    dev.open_sync()

    prints = dev.list_prints_sync()
    print("num prints stored: %d" % len(prints))
    for p in prints:
        print('deleting print:')
        date = p.props.enroll_date
        print('    %04d-%02d-%02d valid: %d' % (date.get_year(), date.get_month(), date.get_day(), date.valid()))
        print('    ' + str(p.props.finger))
        print('    ' + str(p.props.username))
        print('    ' + str(p.props.description))

        dev.delete_print_sync(p)

        print('deleted')

    dev.close_sync()
