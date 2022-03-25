local lgi = require('lgi')
local Gio = lgi.require('Gio')
local Application = Gio.Application.new("lib.mini", Gio.ApplicationFlags.FLAGS_NONE);
Application:register()

Notifeir = {
    notify = function(self, title, message)
        if title and message then
            local Notification = Gio.Notification.new(title)
            Notification:set_body(message)
            local Icon = Gio.ThemedIcon.new("dialog-information")
            Notification:set_icon(Icon)
            Application:send_notification(nil, Notification)
        end
    end
}

--Notifeir:notify(arg[1], arg[2])

return Notifeir
