- [Создаем процесс test](#создаем_процесс_test)





1. Создаем скрипт my_test.sh

Командой 
```bash
nano my_test.sh
```

Скрипт будет исполнять бесконечный цикл ожидания

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

Cделаем наш файл test (который ссылается на скрипт my_test.sh) исполняемым в фоновом режиме.
```bash
./test &
```

# Создаем процесс test


