#Использовать 1commands
#Использовать fs
#Использовать tempfiles

Перем ЭтоWindows;

Процедура ВыполнитьКоманду(Знач Команда) Экспорт
	ВерсияКУстановке = Команда.ЗначениеАргумента("VERSION");
	УстановитьOneScript(ВерсияКУстановке);
КонецПроцедуры

Процедура УстановитьOneScript(Знач ВерсияКУстановке)
	
	ПроверитьКорректностьПереданнойВерсии(ВерсияКУстановке);

	КаталогУстановки = ПараметрыПриложения.КаталогУстановкиПоУмолчанию();
	КаталогУстановкиВерсии = ОбъединитьПути(КаталогУстановки, ВерсияКУстановке);
	ФС.ОбеспечитьКаталог(КаталогУстановки);
	ФС.ОбеспечитьПустойКаталог(КаталогУстановкиВерсии);
	
	ФайлУстановщика = СкачатьФайлУстановщика(ВерсияКУстановке);
	
	УстановитьOneScriptИзZipАрхива(ФайлУстановщика, КаталогУстановкиВерсии);
	
	КомандаUse = Новый КомандаUse();
	КомандаUse.ИспользоватьВерсиюOneScript(ВерсияКУстановке);

КонецПроцедуры

Функция СкачатьФайлУстановщика(Знач ВерсияКУстановке)
	
	ПутьКСохраняемомуФайлу = ВременныеФайлы.НовоеИмяФайла("zip");
	
	ПутьКСкачиваниюВерсии = ПолучитьПутьКСкачиваниюФайла(ВерсияКУстановке);
	Ресурс = ПолучитьПутьКСкачиваниюФайла(ВерсияКУстановке);
	Соединение = Новый HTTPСоединение("http://oscript.io");
	Запрос = Новый HTTPЗапрос(Ресурс);
	
	Ответ = Соединение.Получить(Запрос, ПутьКСохраняемомуФайлу);
	
	Если Ответ.КодСостояния <> 200 Тогда
		ВызватьИсключение Ответ.КодСостояния;
	КонецЕсли;
	
	Возврат ПутьКСохраняемомуФайлу;
	
КонецФункции

Процедура УстановитьOneScriptИзZipАрхива(Знач ПутьКФайлуУстановщика, Знач КаталогУстановкиВерсии);
	
	ЧтениеZIPФайла = Новый ЧтениеZipФайла(ПутьКФайлуУстановщика);
	ЧтениеZIPФайла.ИзвлечьВсе(КаталогУстановкиВерсии);
	ЧтениеZIPФайла.Закрыть();
	
КонецПроцедуры

Процедура ПроверитьКорректностьПереданнойВерсии(Знач ВерсияКУстановке)
	Если СтрРазделить(ВерсияКУстановке, ".").Количество() <> 3
		И НРег(ВерсияКУстановке) <> "latest"
		И НРег(ВерсияКУстановке) <> "dev"
		И НРег(ВерсияКУстановке) <> "night-build" Тогда
		
		ВызватьИсключение "Версия имеет некорректный формат";
	КонецЕсли;
КонецПроцедуры

Функция ПолучитьПутьКСкачиваниюФайла(Знач ВерсияКУстановке)
	
	Если СтрРазделить(ВерсияКУстановке, ".").Количество() = 3 Тогда
		КаталогВерсии = СтрЗаменить(ВерсияКУстановке, ".", "_");
		ИмяФайла = СтрШаблон("OneScript-%1.zip", ВерсияКУстановке);
	ИначеЕсли НРег(ВерсияКУстановке) = "latest" ИЛИ НРег(ВерсияКУстановке) = "stable" Тогда
		КаталогВерсии = "latest";
		ИмяФайла = "zip";
	ИначеЕсли НРег(ВерсияКУстановке) = "dev" ИЛИ НРег(ВерсияКУстановке) = "night-build" Тогда
		КаталогВерсии = "night-build";
		ИмяФайла = "zip";
	Иначе
		ВызватьИсключение "Ошибка получения пути к файлу по версии";
	КонецЕсли;

	Ресурс = СтрШаблон("downloads/%1/%2", КаталогВерсии, ИмяФайла);
	Возврат Ресурс;

КонецФункции

СистемнаяИнформация = Новый СистемнаяИнформация;
ЭтоWindows = Найти(ВРег(СистемнаяИнформация.ВерсияОС), "WINDOWS") > 0;
