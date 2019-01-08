#!/usr/bin/lua
local px =  require "Posix"
local uci=  require 'luci.model.uci'

function update_section(curs, conf, type, network, device, ifname)
    local id = nil
    curs:foreach(
        conf, type,
        function(s)
            if s['network'] == network and s['device'] == device and not s["ifname"] then
                id = s['.name']
            end
        end)
    if id then
        curs:set(conf, id, 'ifname', ifname)
    end
end

function main()

    local curs = uci.cursor()

    -- r1d
    update_section(curs, 'wireless', 'wifi-iface', 'lan', 'wl0', 'wl0')
    update_section(curs, 'wireless', 'wifi-iface', 'lan', 'wl1', 'wl1')
    update_section(curs, 'wireless', 'wifi-iface', 'guest', 'wl1', 'wl1.2')

    -- r1cm
    update_section(curs, 'wireless', 'wifi-iface', 'lan', 'mt7612', 'wl0')
    update_section(curs, 'wireless', 'wifi-iface', 'lan', 'mt7620', 'wl1')

    curs:save('wireless')
    curs:commit('wireless')

end

main()




