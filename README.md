##Создаем процесс test

1. Создаем скрипт my_test.sh

Командой 
```bash
nano my_test.sh
```

Скрипт будет исполнять бесконечный цикл ожидания

![image](https://github.com/user-attachments/assets/865630b6-8b80-40b9-ac0b-e07e527aa562)

Создадим символическую ссылку на наш скрипт(назовем ссылку `test`)

```bash
ln -s "$(pwd)/my_test.sh" test
```
