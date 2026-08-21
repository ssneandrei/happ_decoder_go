'use strict';
'require form';
'require uci';
'require view';
'require ui';

return view.extend({
    render: function() {
        var m, s, o;

        m = new form.Map('happ-decoder', _('Happ Decoder'), 
            _('Локальный сервис автоматической расшифровки подписок happ:// для ForkOP, PassWall и OpenClash.'));

        // Секция 1: Настройки службы
        s = m.section(form.NamedSection, 'main', 'global', _('Настройки службы'));

        o = s.option(form.Flag, 'enabled', _('Включить службу'));
        o.rmempty = false;

        o = s.option(form.Value, 'port', _('Порт HTTP-сервера'));
        o.datatype = 'port';
        o.default = '8080';
        o.rmempty = false;

        // Секция 2: Интерактивный декодер ссылок
        s = m.section(form.NamedSection, 'main', 'global', _('Декодер ссылок happ://'));

        o = s.option(form.Value, '_happ_input', _('Ссылка happ://'));
        o.placeholder = 'happ://crypt5/...';
        o.datatype = 'string';

        o = s.option(form.Button, '_decode_btn', _('Действие'));
        o.inputtitle = _('Расшифровать и показать локации');
        o.inputstyle = 'apply';
        o.onclick = function(ev) {
            var input = document.querySelector('input[id$="._happ_input"]');
            var portInput = document.querySelector('input[id$=".port"]');
            var resultContainer = document.getElementById('happ_parsed_results');
            
            if (!input || !input.value) {
                ui.addNotification(null, E('p', _('Введите ссылку happ://')), 'error');
                return;
            }

            var rawUrl = input.value.trim();
            var port = (portInput && portInput.value) ? portInput.value : '8080';
            var host = window.location.hostname;
            var reqUrl = 'http://' + host + ':' + port + '/sub?url=' + encodeURIComponent(rawUrl);

            // Создаем или очищаем контейнер вывода
            if (!resultContainer) {
                var parent = input.closest('.cbi-value');
                resultContainer = E('div', { 
                    'id': 'happ_parsed_results', 
                    'style': 'margin-top: 15px; padding: 12px; background: #f9f9f9; border: 1px solid #ccc; border-radius: 6px;' 
                });
                parent.parentNode.appendChild(resultContainer);
            }
            resultContainer.innerHTML = '<i>Загрузка и расшифровка...</i>';

            // Отправляем запрос к локальному Go-сервису
            fetch(reqUrl)
                .then(function(res) {
                    if (!res.ok) throw new Error('Ошибка HTTP: ' + res.status);
                    return res.text();
                })
                .then(function(text) {
                    resultContainer.innerHTML = '';

                    // Разбиваем содержимое по строкам
                    var lines = text.split('\n').map(function(l) { return l.trim(); }).filter(Boolean);

                    if (lines.length === 0) {
                        resultContainer.appendChild(E('p', { 'style': 'color: red;' }, _('Подписка пуста или не удалось расшифровать.')));
                        return;
                    }

                    // Общая локальная ссылка для всей подписки целиком
                    resultContainer.appendChild(E('div', { 'style': 'margin-bottom: 15px; padding-bottom: 10px; border-bottom: 1px solid #ddd;' }, [
                        E('strong', {}, _('Ссылка подписки целиком (для ForkOP / PassWall):')),
                        E('input', { 
                            'type': 'text', 
                            'readonly': 'readonly', 
                            'value': reqUrl, 
                            'style': 'width: 100%; margin-top: 5px; padding: 6px; font-family: monospace;',
                            'onclick': function() { this.select(); }
                        })
                    ]));

                    // Вывод найденных локаций списком поштучно
                    resultContainer.appendChild(E('strong', {}, _('Найдено локаций: ') + lines.length));

                    var list = E('div', { 'style': 'margin-top: 10px; max-height: 400px; overflow-y: auto;' });

                    lines.forEach(function(line, idx) {
                        // Попытка извлечь название сервера из хеша (#Имя)
                        var label = 'Локация #' + (idx + 1);
                        if (line.includes('#')) {
                            try {
                                label = decodeURIComponent(line.split('#')[1]);
                            } catch(e) {
                                label = line.split('#')[1];
                            }
                        }

                        var item = E('div', { 'style': 'display: flex; align-items: center; gap: 8px; margin-bottom: 8px; background: #fff; padding: 6px 10px; border: 1px solid #e0e0e0; border-radius: 4px;' }, [
                            E('span', { 'style': 'font-weight: bold; min-width: 130px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;' }, label),
                            E('input', { 
                                'type': 'text', 
                                'readonly': 'readonly', 
                                'value': line, 
                                'style': 'flex-grow: 1; font-size: 11px; font-family: monospace; padding: 4px;',
                                'onclick': function() { this.select(); }
                            }),
                            E('button', {
                                'class': 'btn cbi-button cbi-button-apply',
                                'style': 'padding: 3px 8px; font-size: 11px;',
                                'click': function(ev) {
                                    navigator.clipboard.writeText(line).then(function() {
                                        ui.addNotification(null, E('p', _('Скопировано в буфер!')), 'info');
                                    });
                                }
                            }, _('Копировать'))
                        ]);

                        list.appendChild(item);
                    });

                    resultContainer.appendChild(list);
                })
                .catch(function(err) {
                    resultContainer.innerHTML = '';
                    resultContainer.appendChild(E('p', { 'style': 'color: red;' }, _('Ошибка обращения к декодеру: ') + err.message));
                });
        };

        return m.render();
    }
});
