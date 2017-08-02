#Использовать logos
#Использовать tempfiles
#Использовать fs
#Использовать json
#Использовать ParserFileV8i
#Использовать strings

Перем Лог;

Функция ПодключитьРаннер() Экспорт // TODO удалить  метод после рефакторинга
	Путь = ОбъединитьПути(КаталогПроекта(), "tools", "runner.os");
	ПодключитьСценарий(Путь, "runner");
	runner = Новый runner();
	Возврат runner;
КонецФункции

Функция ЗапуститьПроцесс(Знач СтрокаВыполнения) Экспорт
	Перем ПаузаОжиданияЧтенияБуфера;
	
	ПаузаОжиданияЧтенияБуфера = 10;
	
	Лог = ПолучитьЛог();
	Лог.Отладка(СтрокаВыполнения);
	Процесс = СоздатьПроцесс(СтрокаВыполнения,,Истина);
	Процесс.Запустить();
	
	ТекстБазовый = "";
	Счетчик = 0; МаксСчетчикЦикла = 100000;
	
	Пока Истина Цикл 
		Текст = Процесс.ПотокВывода.Прочитать();
		Лог.Отладка("Цикл ПотокаВывода "+Текст);
		Если Текст = Неопределено ИЛИ ПустаяСтрока(СокрЛП(Текст))  Тогда 
			Прервать;
		КонецЕсли;
		Счетчик = Счетчик + 1;
		Если Счетчик > МаксСчетчикЦикла Тогда 
			Прервать;
		КонецЕсли;
		ТекстБазовый = ТекстБазовый + Текст;
		
		sleep(ПаузаОжиданияЧтенияБуфера); //Подождем, надеюсь буфер не переполниться. 
		
	КонецЦикла;
	
	Процесс.ОжидатьЗавершения();
	
	Если Процесс.КодВозврата = 0 Тогда
		Текст = Процесс.ПотокВывода.Прочитать();
		Если Текст = Неопределено ИЛИ ПустаяСтрока(СокрЛП(Текст)) Тогда 

		Иначе
			ТекстБазовый = ТекстБазовый + Текст;
		КонецЕсли;
		Лог.Отладка(ТекстБазовый);
		Возврат ТекстБазовый;
	Иначе
		ВызватьИсключение "Сообщение от процесса 
		| код:" + Процесс.КодВозврата + " процесс: "+ Процесс.ПотокОшибок.Прочитать();
	КонецЕсли;	

КонецФункции

Функция ПрочитатьФайлИнформации(Знач ПутьКФайлу) Экспорт

	Текст = "";
	Файл = Новый Файл(ПутьКФайлу);
	Если Файл.Существует() Тогда
		Чтение = Новый ЧтениеТекста(Файл.ПолноеИмя);
		Текст = Чтение.Прочитать();
		Чтение.Закрыть();
	Иначе
		Текст = "Информации об ошибке нет";
	КонецЕсли;

	Лог = ПолучитьЛог();
	Лог.Отладка("файл информации:
	|"+Текст);
	Возврат Текст;

КонецФункции

Процедура ДополнитьАргументыИзПеременныхОкружения(Знач СоответствиеПеременных, ЗначенияПараметров) Экспорт
	ПолучитьЛог();

	Для каждого Элемент Из СоответствиеПеременных Цикл
		ЗначениеПеременной = ПолучитьПеременнуюСреды(ВРег(Элемент.Ключ));
		ПараметрКоманднойСтроки = ЗначенияПараметров.Получить(Элемент.Значение);
		Если ПараметрКоманднойСтроки = Неопределено ИЛИ ПустаяСтрока(ПараметрКоманднойСтроки) Тогда 
			Если ЗначениеЗаполнено(ЗначениеПеременной) И НЕ ПустаяСтрока(ЗначениеПеременной) Тогда
				ЗначенияПараметров.Вставить(Элемент.Значение, ЗначениеПеременной);
			КонецЕсли;
		КонецЕсли;
	КонецЦикла;
	Для Каждого Параметр Из ЗначенияПараметров Цикл
		Лог.Отладка("Передан параметр: %1 = %2", Параметр.Ключ, Параметр.Значение);
	КонецЦикла;
	
КонецПроцедуры

Функция ИмяФайлаНастроек() Экспорт
	Возврат "env.json";
КонецФункции // ИмяФайлаНастроек()

Процедура ДополнитьАргументыИзФайлаНастроек(Знач Команда, ЗначенияПараметров, Знач НастройкиИзФайла) Экспорт
	Перем КлючПоУмолчанию, Настройки;
	КлючПоУмолчанию = "default";

	ДополнитьСоответствиеСУчетомПриоритета(ЗначенияПараметров, НастройкиИзФайла.Получить(Команда));
	ДополнитьСоответствиеСУчетомПриоритета(ЗначенияПараметров, НастройкиИзФайла.Получить(КлючПоУмолчанию));

	ПолучитьЛог();
	Для каждого Элемент из ЗначенияПараметров Цикл 
		Лог.Отладка(Элемент.Ключ + ":"+Элемент.Значение);
	КонецЦикла;

КонецПроцедуры //ДополнитьАргументыИзФайлаНастроек

Процедура ДополнитьСоответствиеСУчетомПриоритета(КоллекцияОсновная, Знач КоллекцияДоп = Неопределено)
	Если КоллекцияДоп = Неопределено Тогда 
		Возврат;
	КонецЕсли;

	Для Каждого Элемент из КоллекцияДоп Цикл 
		Значение = КоллекцияОсновная.Получить(Элемент.Ключ);
		Если НЕ ЗначениеЗаполнено(Значение) Тогда 
			КоллекцияОсновная.Вставить(Элемент.Ключ, Элемент.Значение);
		КонецЕсли;
	КонецЦикла;
КонецПроцедуры //ДополнитьСоответствиеСУчетомПриоритета

Функция ПереопределитьПолныйПутьВСтрокеПодключения(Знач СтрокаПодключения) Экспорт
	ПолучитьЛог().Отладка(СтрокаПодключения);
	Если Лев(СтрокаПодключения,2)="/F" Тогда
		ПутьКБазе = УбратьКавычкиВокругПути(Сред(СтрокаПодключения, 3));
		ПутьКБазе = ПолныйПуть(ПутьКБазе);
		СтрокаПодключения = "/F""" + ПутьКБазе + """"
	КонецЕсли;
	Возврат СтрокаПодключения;
КонецФункции // ПереопределитьПолныйПутьВСтрокеПодключения()

Функция ПрочитатьНастройкиФайлJSON(Знач ТекущийКаталогПроекта, Знач ПутьКФайлу = Неопределено ) Экспорт
	ИмяФайлаНастроек = ИмяФайлаНастроек();

	Лог.Отладка(":"+ПутьКФайлу+":"+ИмяФайлаНастроек);
	Если ПутьКФайлу = Неопределено ИЛИ НЕ ЗначениеЗаполнено(ПутьКФайлу) Тогда 
		ПутьКФайлу = ОбъединитьПути(ТекущийКаталогПроекта, ИмяФайлаНастроек);
	КонецЕсли;
	Лог.Отладка(ПутьКФайлу);

	Возврат ПрочитатьФайлJSON(ПутьКФайлу);
КонецФункции

Функция ПрочитатьФайлJSON(Знач ИмяФайла) Экспорт
	Лог.Отладка(ИмяФайла);
	ФайлСуществующий = Новый Файл(ИмяФайла);
	Если Не ФайлСуществующий.Существует() Тогда
		Возврат Новый Соответствие;
	КонецЕсли;
	Чтение = Новый ЧтениеТекста(ИмяФайла, КодировкаТекста.UTF8);
	JsonСтрока  = Чтение.Прочитать();
	Чтение.Закрыть();
	ПарсерJSON  = Новый ПарсерJSON();
	Результат   = ПарсерJSON.ПрочитатьJSON(JsonСтрока);

	Возврат Результат;
КонецФункции

// TODO возможно, лучше просто передавать параметры для инкапсуляции знания об "--ordinaryapp" в одном месте
Функция УказанПараметрТолстыйКлиент(Знач ПараметрТолстыйКлиентИзКоманднойСтроки, Знач Лог) Экспорт
	Если ПараметрТолстыйКлиентИзКоманднойСтроки = Неопределено Тогда
		ЗапускатьТолстыйКлиент = Ложь;
		ОписаниеПараметра = "Не задан параметр --ordinaryapp";
	Иначе
		ЗапускатьТолстыйКлиент = ПараметрТолстыйКлиентИзКоманднойСтроки = Истина
			ИЛИ СокрЛП(Строка(ПараметрТолстыйКлиентИзКоманднойСтроки)) = "1" ;
		ОписаниеПараметра = СтрШаблон("Передан параметр --ordinaryapp, равный %1,", ПараметрТолстыйКлиентИзКоманднойСтроки);
	КонецЕсли;
	
	Лог.Отладка(СтрШаблон("%1 для выбора режима толстого/тонкого клиента", ОписаниеПараметра));
	Если ЗапускатьТолстыйКлиент Тогда
		Лог.Отладка("Выбран режим запуска - толстый клиент 1С.");
	Иначе
		Лог.Отладка("Выбран режим запуска - тонкий клиент 1С.");
	КонецЕсли;
	
	Возврат ЗапускатьТолстыйКлиент;
КонецФункции

Функция ПолучитьИмяВременногоФайлаВКаталоге(Знач Каталог, Знач Расширение = "") Экспорт
	ПревКаталог = ВременныеФайлы.БазовыйКаталог;
	ВременныеФайлы.БазовыйКаталог = Каталог;
	ИмяВременногоФайла = ВременныеФайлы.НовоеИмяФайла(Расширение);
	ВременныеФайлы.БазовыйКаталог = ПревКаталог;
	Возврат ИмяВременногоФайла;
КонецФункции

// TODO перенести в библиотеку ФС/fs
Процедура УдалитьФайлЕслиОнСуществует(Знач ПутьФайла) Экспорт
	ПутьФайла = ОбъединитьПути(ТекущийКаталог(), ПутьФайла);
	Файл = Новый Файл(ПутьФайла);	
	Если Файл.Существует() Тогда
		УдалитьФайлы(ПутьФайла);
	КонецЕсли;
КонецПроцедуры

Процедура ОбеспечитьПустойКаталог(Знач ФайлОбъектКаталога) Экспорт

	//TODO заменить ОбеспечитьПустойКаталог на ФС.ОбеспечитьПустойКаталог
	ФС.ОбеспечитьПустойКаталог(ФайлОбъектКаталога.ПолноеИмя);
	
КонецПроцедуры

Функция ОбернутьПутьВКавычки(Знач Путь) Экспорт

	Результат = Путь;
	Если Прав(Результат, 1) = "\" ИЛИ Прав(Результат, 1) = "/" Тогда
		Результат = Лев(Результат, СтрДлина(Результат) - 1);
	КонецЕсли;

	Результат = """" + Результат + """";

	Возврат Результат;

КонецФункции

Функция УбратьКавычкиВокругПути(Знач Путь) Экспорт
	//NOTICE: https://github.com/xDrivenDevelopment/precommit1c 
	//Apache 2.0 
	ОбработанныйПуть = Путь;

	Если Лев(ОбработанныйПуть, 1) = """" Тогда
		ОбработанныйПуть = Прав(ОбработанныйПуть, СтрДлина(ОбработанныйПуть) - 1);
	КонецЕсли;
	Если Прав(ОбработанныйПуть, 1) = """" Тогда
		ОбработанныйПуть = Лев(ОбработанныйПуть, СтрДлина(ОбработанныйПуть) - 1);
	КонецЕсли;
	
	Возврат ОбработанныйПуть;
	
КонецФункции

Функция ПолныйПуть(Знач Путь, Знач КаталогПроекта = "") Экспорт
	Перем ФайлПуть;
	
	Если ПустаяСтрока(Путь) Тогда 
		Возврат Путь;
	КонецЕсли;

	Если ПустаяСтрока(КаталогПроекта) Тогда
		КаталогПроекта = ПараметрыСистемы.КорневойПутьПроекта;
	КонецЕсли;

	Если Лев(Путь, 1) = "." Тогда 
		Путь = ОбъединитьПути(КаталогПроекта, Путь);
	КонецЕсли;
	
	ФайлПуть = Новый Файл(Путь);

	Возврат ФайлПуть.ПолноеИмя
	
КонецФункции //ПолныйПуть()

Функция КаталогПроекта() Экспорт
	ФайлИсточника = Новый Файл(ТекущийСценарий().Источник);
	Возврат ОбъединитьПути(ФайлИсточника.Путь, "..", "..");
КонецФункции

Функция ПолучитьЛог()
	Если Лог = Неопределено Тогда
		Лог = Логирование.ПолучитьЛог(ПараметрыСистемы.ИмяЛогаСистемы());
	КонецЕсли;
	Возврат Лог;	
КонецФункции

Функция ТипФайлаПоддерживается(Знач Файл) Экспорт
	Если ПустаяСтрока(Файл.Расширение) Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Поз = Найти(".epf,.erf,", Файл.Расширение+",");
	Возврат Поз > 0;
	
КонецФункции


// из-за особенностей загрузки модуль ОбщиеМетоды грузится раньше ПараметрыСистемы, 
//поэтому сразу в конце кода модуля использовать ПараметрыСистемы нельзя
