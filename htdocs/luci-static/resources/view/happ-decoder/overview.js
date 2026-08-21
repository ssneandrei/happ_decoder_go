'use strict';
'require form';
'require uci';
'require view';

return view.extend({
    render: function() {
        var m, s, o;

        m = new form.Map('happ-decoder', _('Happ Decoder'), 
            _('Локальный сервис автоматической расшифровки подписок happ:// для PassWall, OpenClash и Nikki.'));

        s = m.section(form.NamedSection, 'main', 'global', _('Настройки службы'));

        o = s.option(form.Flag, 'enabled', _('Включить службу'));
        o.rmempty = false;

        o = s.option(form.Value, 'port', _('Порт HTTP-сервера'));
        o.datatype = 'port';
        o.default = '8080';
        o.rmempty = false;

        return m.render();
    }
});
