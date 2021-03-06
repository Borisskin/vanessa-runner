///////////////////////////////////////////////////////////////////
//
// Служебный модуль с набором методов работы с командами приложения
//
// Структура модуля реализована в соответствии с рекомендациями
// oscript-app-template (C) EvilBeaver
//
///////////////////////////////////////////////////////////////////

#Использовать logos
#Использовать v8runner

Перем Лог;
Перем КорневойПутьПроекта;

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт

	ТекстОписания =
		"     Обновление базы данных для выполнения необходимых тестов.
		|";

	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, ТекстОписания);

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--src", "Путь к папке исходников
	|
	|Схема работы:
	|		Указываем путь к исходникам с конфигурацией,
	|		указываем версию платформы, которую хотим использовать,
	|		и получаем по пути build\ib готовую базу для тестирования.");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--dt", "Путь к файлу с dt выгрузкой");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--dev",
		"Признак dev режима, создаем и загружаем автоматом структуру конфигурации");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--disable-support",
		"Снимает конфигурации с поддержки перед загрузкой исходников");	
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--storage", "Признак обновления из хранилища");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--storage-name", "Строка подключения к хранилищу");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--storage-user", "Пользователь хранилища");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--storage-pwd", "Пароль");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--storage-ver",
		"Номер версии, по умолчанию берем последнюю");

	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--v1",
		"Поддержка режима реструктуризации -v1 на сервере");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "--v2",
		"Поддержка режима реструктуризации -v2 на сервере");

	Парсер.ДобавитьКоманду(ОписаниеКоманды);

КонецПроцедуры // ЗарегистрироватьКоманду

// Выполняет логику команды
//
// Параметры:
//   ПараметрыКоманды - Соответствие - Соответствие ключей командной строки и их значений
//   ДополнительныеПараметры - Соответствие - дополнительные параметры (необязательно)
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды, Знач ДополнительныеПараметры = Неопределено) Экспорт

	Лог = ДополнительныеПараметры.Лог;
	КорневойПутьПроекта = ПараметрыСистемы.КорневойПутьПроекта;

	ДанныеПодключения = ПараметрыКоманды["ДанныеПодключения"];

	ПараметрыХранилища = Новый Структура;
	ПараметрыХранилища.Вставить("СтрокаПодключения", ПараметрыКоманды["--storage-name"]);
	ПараметрыХранилища.Вставить("Пользователь", ПараметрыКоманды["--storage-user"]);
	ПараметрыХранилища.Вставить("Пароль", ПараметрыКоманды["--storage-pwd"]);
	ПараметрыХранилища.Вставить("Версия", ПараметрыКоманды["--storage-ver"]);
	ПараметрыХранилища.Вставить("РежимОбновления", ПараметрыКоманды["--storage"]);

	РежимыРеструктуризации = Новый Структура;
	РежимыРеструктуризации.Вставить("Первый", ПараметрыКоманды["--v1"]);
	РежимыРеструктуризации.Вставить("Второй", ПараметрыКоманды["--v2"]);

	ОбновитьБазуДанных(ПараметрыКоманды["--src"], ПараметрыКоманды["--dt"],
					ДанныеПодключения,
					ПараметрыКоманды["--uccode"],
					ПараметрыКоманды["--v8version"], ПараметрыКоманды["--dev"],
					ПараметрыХранилища,
					ДанныеПодключения.КодЯзыка, РежимыРеструктуризации,
					ПараметрыКоманды["--disable-support"]);

	Возврат МенеджерКомандПриложения.РезультатыКоманд().Успех;

КонецФункции // ВыполнитьКоманду

Процедура ОбновитьБазуДанных(Знач ПутьКSRC, Знач ПутьКDT,
		Знач ДанныеПодключения,
		Знач КлючРазрешенияЗапуска, Знач ВерсияПлатформы, Знач РежимРазработчика,
		Знач ПараметрыХранилища,
		Знач КодЯзыка, РежимыРеструктуризации,
		Знач СниматьСПоддержки)

	Перем БазуСоздавали;
	БазуСоздавали = Ложь;
	ТекущаяПроцедура = "Запускаем обновление";

	СтрокаПодключения = ДанныеПодключения.ПутьБазы;
	Пользователь = ДанныеПодключения.Пользователь;
	Пароль = ДанныеПодключения.Пароль;

	СтрокаПодключенияХранилище = ПараметрыХранилища.СтрокаПодключения;
	ПользовательХранилища = ПараметрыХранилища.Пользователь;
	ПарольХранилища = ПараметрыХранилища.Пароль;
	ВерсияХранилища = ПараметрыХранилища.Версия;
	РежимОбновленияХранилища = ПараметрыХранилища.РежимОбновления;

	Логирование.ПолучитьЛог("oscript.lib.v8runner").УстановитьУровень(Лог.Уровень());

	Если РежимРазработчика = Истина Тогда
		КаталогБазы = ОбъединитьПути(КорневойПутьПроекта, "./build/ibservice");
		СтрокаПодключения = "/F""" + КаталогБазы + """";
	КонецЕсли;

	Если ПустаяСтрока(СтрокаПодключения) Тогда
		КаталогБазы = ОбъединитьПути(КорневойПутьПроекта, ?(РежимРазработчика = Истина, "./build/ibservice", "./build/ib"));
		СтрокаПодключения = "/F""" + КаталогБазы + """";
	КонецЕсли;

	Лог.Отладка("ИнициализироватьБазуДанных СтрокаПодключения:" + СтрокаПодключения);

	Если Лев(СтрокаПодключения, 2) = "/F" Тогда
		КаталогБазы = ОбщиеМетоды.УбратьКавычкиВокругПути(Сред(СтрокаПодключения, 3, СтрДлина(СтрокаПодключения) - 2));
		ФайлБазы = Новый Файл(КаталогБазы);
		Ожидаем.Что(ФайлБазы.Существует(), ТекущаяПроцедура + " папка с базой существует").ЭтоИстина();
	КонецЕсли;

	МенеджерКонфигуратора = Новый МенеджерКонфигуратора;
	// При первичной инициализации опускаем указание пользователя и пароля, т.к. их еще нет.
	МенеджерКонфигуратора.Инициализация(
		СтрокаПодключения, "", "",
		ВерсияПлатформы, КлючРазрешенияЗапуска,
		КодЯзыка
		);

	Конфигуратор = МенеджерКонфигуратора.УправлениеКонфигуратором();

	Конфигуратор.УстановитьИмяФайлаСообщенийПлатформы(ВременныеФайлы.НовоеИмяФайла("log"));

	Конфигуратор.УстановитьКонтекст(СтрокаПодключения, "", "");
	Если Не ПустаяСтрока(ПутьКDT) Тогда
		ПутьКDT = Новый Файл(ОбъединитьПути(КорневойПутьПроекта, ПутьКDT)).ПолноеИмя;
		Лог.Информация("Загружаем dt " + ПутьКDT);
		Попытка
			Конфигуратор.УстановитьКонтекст(СтрокаПодключения, Пользователь, Пароль);
			Конфигуратор.ЗагрузитьИнформационнуюБазу(ПутьКDT);
		Исключение
			Лог.Ошибка("Не удалось загрузить:" + ОписаниеОшибки());
		КонецПопытки;
	КонецЕсли;

	Конфигуратор.УстановитьКонтекст(СтрокаПодключения, Пользователь, Пароль);

	Если Не ПустаяСтрока(ПутьКSRC) Тогда
		Лог.Информация("Запускаю загрузку конфигурации из исходников");
		ПутьКSRC = Новый Файл(ОбъединитьПути(КорневойПутьПроекта, ПутьКSRC)).ПолноеИмя;
		СписокФайлов = "";
		МенеджерКонфигуратора.СобратьИзИсходниковТекущуюКонфигурацию(
			ПутьКSRC, СписокФайлов, СниматьСПоддержки);
	КонецЕсли;

	Попытка

		Если РежимОбновленияХранилища = Истина Тогда
			Лог.Информация("Обновляем из хранилища");

			МенеджерКонфигуратора.ЗапуститьОбновлениеИзХранилища(
				СтрокаПодключенияХранилище, ПользовательХранилища, ПарольХранилища,
				ВерсияХранилища);
		КонецЕсли;

		Если РежимРазработчика = Ложь Или РежимыРеструктуризации.Первый Или РежимыРеструктуризации.Второй Тогда
			ОбщиеМетоды.ОбновитьКонфигурациюБД(МенеджерКонфигуратора,
				РежимыРеструктуризации.Первый, РежимыРеструктуризации.Второй);
		КонецЕсли;

	Исключение
		МенеджерКонфигуратора.Деструктор();
		ВызватьИсключение ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
	КонецПопытки;

	МенеджерКонфигуратора.Деструктор();

КонецПроцедуры // ОбновитьБазуДанных
