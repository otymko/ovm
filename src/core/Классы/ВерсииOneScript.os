#Использовать 1commands
#Использовать fluent
#Использовать fs

Перем ЭтоWindows;

Функция ВерсияУстановлена(Знач ПроверяемаяВерсия) Экспорт

	КаталогУстановки = ПараметрыOVM.КаталогУстановкиПоУмолчанию();
	КаталогУстановкиВерсии = ОбъединитьПути(КаталогУстановки, ПроверяемаяВерсия);
	
	Результат = ФС.КаталогСуществует(КаталогУстановкиВерсии);
	Результат = Результат И ФС.ФайлСуществует(ОбъединитьПути(КаталогУстановкиВерсии, "bin", "oscript.exe"));

	Возврат Результат;

КонецФункции

Функция ЭтоТекущаяВерсия(Знач ПроверяемаяВерсия) Экспорт

	Если ПроверяемаяВерсия = "current" Тогда
		Возврат Истина;
	КонецЕсли;
	
	Если НЕ ВерсияУстановлена("current") Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Если НЕ ВерсияУстановлена(ПроверяемаяВерсия) Тогда
		Возврат Ложь;
	КонецЕсли;

	ПутьКДвижкуТекущейВерсии = ПолучитьПутьКУстановленнойВерсии("current");
	ПутьКДвижкуПроверяемойВерсии = ПолучитьПутьКУстановленнойВерсии(ПроверяемаяВерсия);
	
	ФайлДвижкаТекущейВерсии = Новый Файл(ПутьКДвижкуТекущейВерсии);
	ФайлДвижкаПроверяемойВерсии = Новый Файл(ПутьКДвижкуПроверяемойВерсии);
	
	ФайлыПроверяемойВерсииСовпадаетСТекущейВерсией =
		ФайлДвижкаТекущейВерсии.ПолучитьВремяИзменения() = ФайлДвижкаПроверяемойВерсии.ПолучитьВремяИзменения()
			И ФайлДвижкаТекущейВерсии.ПолучитьВремяСоздания() = ФайлДвижкаПроверяемойВерсии.ПолучитьВремяСоздания();

	Возврат ФайлыПроверяемойВерсииСовпадаетСТекущейВерсией;

КонецФункции

Функция ПолучитьСписокУстановленныхВерсий() Экспорт
	
	УстановленныеВерсии = Новый ТаблицаЗначений;
	УстановленныеВерсии.Колонки.Добавить("Алиас");
	УстановленныеВерсии.Колонки.Добавить("Путь");
	УстановленныеВерсии.Колонки.Добавить("Версия");
	УстановленныеВерсии.Колонки.Добавить("ЭтоСимлинк");
	
	// TODO: определение симлинка на основании аттрибутов файла?
	МассивИменСимлинков = Новый Массив;
	МассивИменСимлинков.Добавить("current");
	// TODO: Раскомментировать для/после реализации https://github.com/silverbulleters/ovm/issues/16
	//МассивИменСимлинков.Добавить("dev");
	//МассивИменСимлинков.Добавить("latest");

	КаталогУстановки = ПараметрыOVM.КаталогУстановкиПоУмолчанию();
	НайденныеФайлы = НайтиФайлы(КаталогУстановки, ПолучитьМаскуВсеФайлы());
	Для Каждого НайденныйФайл Из НайденныеФайлы Цикл
		Если НЕ ВерсияУстановлена(НайденныйФайл.Имя) Тогда
			Продолжить;
		КонецЕсли;
		
		СтрокаВерсии = УстановленныеВерсии.Добавить();
		СтрокаВерсии.Алиас = НайденныйФайл.Имя;
		СтрокаВерсии.Путь = НайденныйФайл.ПолноеИмя;
		СтрокаВерсии.Версия = ПолучитьТочнуюВерсиюOneScript(СтрокаВерсии.Алиас);
		СтрокаВерсии.ЭтоСимлинк = МассивИменСимлинков.Найти(НайденныйФайл.Имя) <> Неопределено;

	КонецЦикла;
	
	Возврат УстановленныеВерсии;
	
КонецФункции

Функция ПолучитьСписокДоступныхКУстановкеВерсий() Экспорт
	
	ДоступныеВерсии = Новый ТаблицаЗначений;
	ДоступныеВерсии.Колонки.Добавить("Алиас");
	ДоступныеВерсии.Колонки.Добавить("Путь");
	
	Соединение = Новый HTTPСоединение("http://oscript.io");
	Запрос = Новый HTTPЗапрос("downloads/archive");
	
	Ответ = Соединение.Получить(Запрос);
	Если Ответ.КодСостояния <> 200 Тогда
		ВызватьИсключение Ответ.КодСостояния;
	КонецЕсли;
	
	ТелоСтраницы = Ответ.ПолучитьТелоКакСтроку();
	
	РегулярноеВыражение = Новый РегулярноеВыражение("<a href=""(\/downloads\/[^""]+)"">(\d+\.\d+\.\d+(\.\d+)?)");
	Совпадения = РегулярноеВыражение.НайтиСовпадения(ТелоСтраницы);
	Для Каждого СовпадениеРегулярногоВыражения Из Совпадения Цикл
		ГруппаАдрес = СовпадениеРегулярногоВыражения.Группы[1];
		ГруппаВерсия = СовпадениеРегулярногоВыражения.Группы[2];
		
		ДоступнаяВерсия = ДоступныеВерсии.Добавить();
		ДоступнаяВерсия.Алиас = ГруппаВерсия.Значение;
		ДоступнаяВерсия.Путь = "http://oscript.io" + ГруппаАдрес.Значение;
	КонецЦикла;

	Возврат ДоступныеВерсии;

КонецФункции

Функция ПолучитьТочнуюВерсиюOneScript(Знач ПроверяемаяВерсия)

	КаталогУстановки = ПараметрыOVM.КаталогУстановкиПоУмолчанию();
	КаталогУстановкиВерсии = ОбъединитьПути(КаталогУстановки, ПроверяемаяВерсия);
	ПутьКИсполняемомуФайлу = ОбъединитьПути(КаталогУстановкиВерсии, "bin", "oscript.exe");
	
	Команда = Новый Команда();
	
	Если ЭтоWindows Тогда
		Команда.УстановитьКоманду(ПутьКИсполняемомуФайлу);
	Иначе
		Команда.УстановитьКоманду("mono");
		Команда.ДобавитьПараметр(ПутьКИсполняемомуФайлу);
	КонецЕсли;
	
	Команда.ДобавитьПараметр("-version");
	
	Команда.Исполнить();
	
	ВыводКоманды = СокрЛП(Команда.ПолучитьВывод());
	
	Возврат ВыводКоманды;
	
КонецФункции

Функция ПолучитьПутьКУстановленнойВерсии(Знач УстановленнаяВерсия) Экспорт
	УстановленныеВерсии = ПолучитьСписокУстановленныхВерсий();
	ПроцессорКоллекций = Новый ПроцессорКоллекций();
	ПроцессорКоллекций.УстановитьКоллекцию(УстановленныеВерсии);

	ДополнительныеПараметры = Новый Структура("УстановленнаяВерсия", УстановленнаяВерсия);
	ПутьКУстановленнойВерсии = ПроцессорКоллекций
		.Фильтровать(
			"Результат = Элемент.Алиас = ДополнительныеПараметры.УстановленнаяВерсия",
			ДополнительныеПараметры
		)
		.Обработать("Результат = Элемент.Путь")
		.Обработать("Результат = ОбъединитьПути(Элемент, ""bin"", ""oscript.exe"")")
		.ПолучитьПервый();
	
	Возврат ПутьКУстановленнойВерсии;
	
КонецФункции

СистемнаяИнформация = Новый СистемнаяИнформация;
ЭтоWindows = Найти(ВРег(СистемнаяИнформация.ВерсияОС), "WINDOWS") > 0;
