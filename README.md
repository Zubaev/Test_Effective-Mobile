***
- [Создание процесса test](#создаем-процесс-test)
- [Создание скрипта мониторинга процесса](#Создание-скрипта-мониторинга-процесса)
- [Unit systemd и Таймер](#Unit-systemd-и-Таймер)

***
# Создаем процесс test
Создадим процесс, который будет вечно "жить" в системе под именем `test`, не делая ничего полезного, но позволяя отслеживать себя средствами мониторинга.


В качестве процесса будет использоваться скрипт, который просто ожидает.

Создаем скрипт `my_test.sh`.
```bash
nano my_test.sh
```

Скрипт имитирует постоянную работу процесса: он ничего не делает, просто "спит", тем самым оставаясь живым в системе. Это позволит нам протестировать, как работает мониторинг — как если бы у меня был реальный процесс.

```bash
#!/bin/bash
while true; do
    sleep 60
done
```

![image](https://github.com/user-attachments/assets/865630b6-8b80-40b9-ac0b-e07e527aa562)

Даем ему права на исполнение:
```bash
chmod +x my_test.sh
```

Создадим символическую ссылку на наш скрипт(назовем ссылку `test`).

```bash
ln -s "$(pwd)/my_test.sh" test
```

Запускаем наш фейковый процесс в фоне. Он начнёт бесконечно "спать" и будет жить, пока его не остановить.
```bash
./test &
```

Проверяем наш процесс.
```bash
pgrep -a test
```
![image](https://github.com/user-attachments/assets/9cc83381-97aa-4169-90ba-23b718556f5c)

Процесс успешно создан и работает.

***

# Создание скрипта мониторинга процесса 

Создаем [скрипт](https://github.com/Zubaev/Test_Effective-Mobile/blob/main/process_status.sh) мониторинга процесса.

Разберем скрипт по частям.

Сохраним все необходимые значения в переменные для удобства их последующего использования.

Чтобы отслеживать, в каком состоянии был процесс раньше, и понимать, перезапускался ли он, добавим дополнительный файл — `process_status_test`.

```bash
PROCESS_NAME="test"
URL="https://test.com/monitoring/test/api"
LOG_FILE="/var/log/monitoring.log"

STATUS_FILE="/var/tmp/process_status_$PROCESS_NAME"
```

Далее необходимо проверить, существует ли уже такой файл. Если нет — создаём его и устанавливаем начальный статус unknown.


```bash
if [ ! -f "$STATUS_FILE" ]; then
    echo "unknown" > "$STATUS_FILE"
fi
```

Затем проверяем, запущен ли процесс. Если да — сохраняем в переменную `CURRENT_STATUS` значение `running`, если нет — `stopped`.

```bash
if pgrep -x "$PROCESS_NAME" > /dev/null; then
    CURRENT_STATUS="running"
else
    CURRENT_STATUS="stopped"
fi
```

Вводим промежуточную переменную, в которую записываем предыдущее состояние процесса.

```bash
PREVIOUS_STATUS=$(cat "$STATUS_FILE")
```

Если процесс сейчас запущен, а в файле указано предыдущее состояние stopped, значит, произошёл перезапуск. Тогда добавляем в лог сообщение с датой, временем и отметкой о перезапуске.

```bash
if [ "$CURRENT_STATUS" == "running" ] && [ "$PREVIOUS_STATUS" == "stopped" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Процесс '$PROCESS_NAME' был перезапущен." >> "$LOG_FILE"
fi
```
Если процесс запущен и не перезапускался, мы отправляем `curl`-запрос по адресу `https://test.com/monitoring/test/api`. Я ограничил время запроса до 5 секунд, чтобы скрипт выполнялся быстрее.

```bash
if [ "$CURRENT_STATUS" == "running" ]; then
    RESPONSE=$(curl --silent --output /dev/null --write-out "%{http_code}" --insecure --max-time 5 "$URL" 2>/dev/null)
```

Если ответ от сервера неуспешный, записываем текущие дату, время и соответствующую запись в лог-файл.

```bash
 if [ "$RESPONSE" != "200" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') Сервер мониторинга недоступен (HTTP $RESPONSE)." >> "$LOG_FILE"
    fi
fi
```

Обновляем состояние файла в `STATUS_FILE` чтобы при следующем выполнении скрипт знал в прошлом состоянии процесса.

```bash
echo "$CURRENT_STATUS" > "$STATUS_FILE"
```

***

# Unit systemd и Таймер
Для начала необходимо сделать наш скрипт исполняемым 

```bash
chmod +x /home/magomed/test/process_status.sh
```

Важно: 
У меня скрипт мониторинга распологается по пути `/home/magomed/test/process_status.sh` находится в домашней дериктории пользователя.

[Папка с service файлом и timer](https://github.com/Zubaev/Test_Effective-Mobile/tree/main/systemd)

Прописываем в файле [monitor_process.service](https://github.com/Zubaev/Test_Effective-Mobile/blob/main/systemd/monitor_process.service) путь с крипту.
Устанавливаем [таймер](https://github.com/Zubaev/Test_Effective-Mobile/blob/main/systemd/monitor_process.timer) на исполнение скрипта каждые 60 секунд.

![image](https://github.com/user-attachments/assets/a7620457-fd95-4b52-b5d1-4b7ba70500d5)


Остановим наш процесс и проверим работает ли он как видно по скриншоту процесс не запущен.

![image](https://github.com/user-attachments/assets/64dba8e9-3bf0-4547-afb5-6c0133632bbb)

Запустим его повторно и проверим лог файл

![image](https://github.com/user-attachments/assets/97859ced-e1c5-4fdf-9c3b-dafe8e2673c2)

Как видим в лог файле появилась надпись о перезапуске процесса.

![image](https://github.com/user-attachments/assets/ce124bab-b5e7-4634-a019-1b7d8f08532d)




