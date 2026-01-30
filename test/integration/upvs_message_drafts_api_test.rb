require "test_helper"

class UpvsMessageDraftsApiTest < ActionDispatch::IntegrationTest
  setup do
    @key_pair = OpenSSL::PKey::RSA.new File.read 'test/fixtures/tenant_test_cert.pem'
    @tenant = tenants(:ssd)
    @box = boxes(:ssd_main)
    @before_request_messages_count = Message.count
  end

  test 'can upload valid message' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        reference_id: SecureRandom.uuid,
        business_id: 'SomeID',
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair)} ), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count
  end

  test 'can upload valid message even if no Posp ID, Posp version' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Návrh na zápis xy s. r. o. do obchodného registra',
      uuid: SecureRandom.uuid,
      metadata: {
        message_type: 'ks_352538',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?mso-application progid="InfoPath.Document" versionProgid="InfoPath.Document.2"?><?mso-infoPath-file-attachment-present ?><?xml-stylesheet type="text/xsl" href="http://eformulare.justice.sk/schemasAndTransformations/FUPS.2023.08.21.xslt" ?><FUPS xmlns="http://www.justice.gov.sk/Forms20230821" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><IdentifikacneUdajeFormulara><Nazov></Nazov><IdentifikatorMFSR></IdentifikatorMFSR><Verzia>1.0.0.1181</Verzia><Popis>PSRO</Popis><NazovGaranta></NazovGaranta><PlatnostOd xsi:nil="true"></PlatnostOd><PlatnostDo xsi:nil="true"></PlatnostDo></IdentifikacneUdajeFormulara><InfoPathData><ID>b76962a3-256a-46b1-87bb-68deff0b03a4</ID><Message></Message><BinaryIn xsi:nil="true"></BinaryIn><BinaryOut xsi:nil="true"></BinaryOut><ValidationResult>0</ValidationResult><ShowWarnings>true</ShowWarnings></InfoPathData><ObchodnyRegister><OkresnySud>Mestský súd Bratislava III</OkresnySud><Ulica>Námestie Biely kríž</Ulica><Cislo>7</Cislo><Obec>Bratislava III</Obec><Psc>83607</Psc><Id>2</Id><Kod>B</Kod></ObchodnyRegister><ZapisatK xsi:nil="true"></ZapisatK><PrilohyKNavrhu><poradoveCislo>1</poradoveCislo><Nazov>Spoločenská zmluva alebo zakladateľská listina</Nazov></PrilohyKNavrhu><PrilohyKNavrhu><poradoveCislo>2</poradoveCislo><Nazov>Listina, ktorou sa preukazuje podnikateľské oprávnenie na vykonávanie činnosti, ktorá sa má do obchodného registra zapísať ako predmet podnikania</Nazov></PrilohyKNavrhu><PrilohyKNavrhu><poradoveCislo>3</poradoveCislo><Nazov>Písomné vyhlásenie správcu vkladu podľa osobitného zákona. (§ 60 ods. 4 Obchodného zákonníka)</Nazov></PrilohyKNavrhu><PrilohyKNavrhu><poradoveCislo>4</poradoveCislo><Nazov>Listina, ktorou sa preukazuje vlastnícke právo alebo užívacie právo k nehnuteľnosti alebo jej časti, ktoré užívanie nehnuteľnosti alebo jej časti ako sídla alebo miesta podnikania nevylučuje, alebo súhlas vlastníka nehnuteľnosti alebo jej časti so zápisom nehnuteľnosti alebo jej časti ako sídla alebo miesta podnikania do obchodného registra podľa osobitného predpisu. (§ 2 ods. 3 Obchodného zákonníka)</Nazov></PrilohyKNavrhu><PrilohyKNavrhu><poradoveCislo>5</poradoveCislo><Nazov>Písomné vyhlásenie zakladateľa, že nie je jediným spoločníkom vo viac ako dvoch spoločnostiach s ručením obmedzeným, ak spoločnosť založila jediná fyzická osoba</Nazov></PrilohyKNavrhu><PrilohyKNavrhu><poradoveCislo>6</poradoveCislo><Nazov>Písomné plnomocenstvo podľa § 5 ods. 3 zákona, ak návrh podáva osoba splnomocnená navrhovateľom</Nazov></PrilohyKNavrhu><Spolocnost>SSD test s. r. o.</Spolocnost><V>Bratislava</V><Dna>2024-12-05</Dna><Postou>true</Postou><Osobne>false</Osobne><NavrhovatelFO><Osoba><TitulPred>Ing.</TitulPred><Meno>Ján</Meno><Priezvisko>Suchal</Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo></RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Adresa><Ulica>Ulica X</Ulica><Cislo>1</Cislo><Obec><Id>529397</Id><StatId></StatId><Value>Bratislava - mestská časť Karlova Ves</Value><Obce></Obce></Obec><Psc>84104</Psc><Stat><Id>703</Id><Value>Slovenská republika</Value></Stat></Adresa></NavrhovatelFO><ObchodneMeno>SSD test s. r. o.</ObchodneMeno><Sidlo><Ulica>Staré grunty</Ulica><Cislo>18</Cislo><Obec><Id>529397</Id><StatId></StatId><Value>Bratislava - mestská časť Karlova Ves</Value><Obce></Obce></Obec><Psc>84104</Psc><Stat><Id>703</Id><Value>Slovenská republika</Value></Stat></Sidlo><Ico></Ico><PravnaForma><Id></Id><Value></Value></PravnaForma><PredmetPodnikania><PoradoveCislo>1</PoradoveCislo><Cinnost>Uskutočňovanie stavieb a ich zmien</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>2</PoradoveCislo><Cinnost>Vypracovanie dokumentácie a projektu jednoduchých stavieb, drobných stavieb a zmien týchto stavieb: stavebná časť</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>3</PoradoveCislo><Cinnost>Kúpa tovaru na účely jeho predaja konečnému spotrebiteľovi (maloobchod) alebo iným prevádzkovateľom živnosti (veľkoobchod)</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>4</PoradoveCislo><Cinnost>Prípravné práce k realizácii stavby</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>5</PoradoveCislo><Cinnost>Dokončovacie stavebné práce pri realizácii exteriérov a interiérov</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>6</PoradoveCislo><Cinnost>Prenájom, úschova a požičiavanie hnuteľných vecí</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>7</PoradoveCislo><Cinnost>Sprostredkovateľská činnosť v oblasti obchodu, služieb, výroby</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>8</PoradoveCislo><Cinnost>Verejné obstarávanie</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>9</PoradoveCislo><Cinnost>Počítačové služby a služby súvisiace s počítačovým spracovaním údajov</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>10</PoradoveCislo><Cinnost>Murárstvo</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>11</PoradoveCislo><Cinnost>Výkon činnosti stavbyvedúceho</Cinnost></PredmetPodnikania><StatutarnyOrganFO><FunkciaClenaStatutarnehoOrganu><Id></Id><Value></Value></FunkciaClenaStatutarnehoOrganu><Funkcia></Funkcia><Osoba><TitulPred>Ing.</TitulPred><Meno>Ján</Meno><Priezvisko>Suchal</Priezvisko><TitulZa></TitulZa><DatumNarodenia>2000-01-01</DatumNarodenia><RodneCislo>000101/8727</RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Bydlisko><Ulica>Ulica X</Ulica><Cislo>1</Cislo><Obec><Id>529397</Id><StatId></StatId><Value>Bratislava - mestská časť Karlova Ves</Value><Obce></Obce></Obec><Psc>84104</Psc><Stat><Id>703</Id><Value>Slovenská republika</Value></Stat></Bydlisko><DenVznikuFunkcie xsi:nil="true"></DenVznikuFunkcie><DenSkonceniaFunkcie xsi:nil="true"></DenSkonceniaFunkcie></StatutarnyOrganFO><StatutarnyOrganSposobKonania>Konateľ koná v mene spoločnosti samostatne.</StatutarnyOrganSposobKonania><OrganizacnaZlozka><OrganizacnaZlozka><Oznacenie></Oznacenie><AdresaUmiestnenia><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></AdresaUmiestnenia><PredmetPodnikania><PoradoveCislo></PoradoveCislo><Cinnost></Cinnost></PredmetPodnikania><Veduci><FunkciaClenaStatutarnehoOrganu><Id></Id><Value></Value></FunkciaClenaStatutarnehoOrganu><Funkcia></Funkcia><Osoba><TitulPred></TitulPred><Meno></Meno><Priezvisko></Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo></RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Bydlisko><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Bydlisko><DenVznikuFunkcie xsi:nil="true"></DenVznikuFunkcie><DenSkonceniaFunkcie xsi:nil="true"></DenSkonceniaFunkcie></Veduci></OrganizacnaZlozka></OrganizacnaZlozka><Prokurista><FunkciaClenaStatutarnehoOrganu><Id></Id><Value></Value></FunkciaClenaStatutarnehoOrganu><Funkcia></Funkcia><Osoba><TitulPred></TitulPred><Meno></Meno><Priezvisko></Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo></RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Bydlisko><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Bydlisko><DenVznikuFunkcie xsi:nil="true"></DenVznikuFunkcie><DenSkonceniaFunkcie xsi:nil="true"></DenSkonceniaFunkcie></Prokurista><ProkuraSposobKonania></ProkuraSposobKonania><SpolocniciFO><Spolocnik><Osoba><TitulPred>Ing.</TitulPred><Meno>Ján</Meno><Priezvisko>Suchal</Priezvisko><TitulZa></TitulZa><DatumNarodenia>2000-01-01</DatumNarodenia><RodneCislo>000101/8727</RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Adresa><Ulica>Ulica X</Ulica><Cislo>1</Cislo><Obec><Id>529397</Id><StatId></StatId><Value>Bratislava - mestská časť Karlova Ves</Value><Obce></Obce></Obec><Psc>84104</Psc><Stat><Id>703</Id><Value>Slovenská republika</Value></Stat></Adresa></Spolocnik><Vklad><VyskaVkladu><Suma>5000</Suma><Mena><Id>6</Id><Value>EUR</Value><Znacka>EUR</Znacka></Mena><TypVkladu><Id>1</Id><Value>peňažný vklad</Value></TypVkladu></VyskaVkladu><RozsahSplatenia><Suma>5000</Suma><Mena><Id>6</Id><Value>EUR</Value><Znacka>EUR</Znacka></Mena></RozsahSplatenia></Vklad></SpolocniciFO><SpolocniciPO><Spolocnik><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa></Spolocnik><Vklad><VyskaVkladu><Suma xsi:nil="true"></Suma><Mena><Id></Id><Value></Value><Znacka></Znacka></Mena><TypVkladu><Id></Id><Value></Value></TypVkladu></VyskaVkladu><RozsahSplatenia><Suma xsi:nil="true"></Suma><Mena><Id></Id><Value></Value><Znacka></Znacka></Mena></RozsahSplatenia></Vklad></SpolocniciPO><Spoluvlastnictvo><SpolocnyObchodnyPodel><VyskaVkladu><Suma xsi:nil="true"></Suma><Mena><Id></Id><Value></Value><Znacka></Znacka></Mena><TypVkladu><Id></Id><Value></Value></TypVkladu></VyskaVkladu><RozsahSplatenia><Suma xsi:nil="true"></Suma><Mena><Id></Id><Value></Value><Znacka></Znacka></Mena></RozsahSplatenia></SpolocnyObchodnyPodel><SpolocnyZastupcaFO><Osoba><TitulPred></TitulPred><Meno></Meno><Priezvisko></Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo></RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa></SpolocnyZastupcaFO><SpolocnyZastupcaPO><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa></SpolocnyZastupcaPO><SpoluvlastnikFO><Osoba><TitulPred></TitulPred><Meno></Meno><Priezvisko></Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo></RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa></SpoluvlastnikFO><SpoluvlastnikPO><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa></SpoluvlastnikPO></Spoluvlastnictvo><DozornaRada><FunkciaClenaStatutarnehoOrganu><Id></Id><Value></Value></FunkciaClenaStatutarnehoOrganu><Funkcia></Funkcia><Osoba><TitulPred></TitulPred><Meno></Meno><Priezvisko></Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo></RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Bydlisko><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Bydlisko><DenVznikuFunkcie xsi:nil="true"></DenVznikuFunkcie><DenSkonceniaFunkcie xsi:nil="true"></DenSkonceniaFunkcie></DozornaRada><KonecniUzivateliaVyhod><Osoba><TitulPred>Ing.</TitulPred><Meno>Ján</Meno><Priezvisko>Suchal</Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo>000101/8727</RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Bydlisko><Ulica>Ulica X</Ulica><Cislo>1</Cislo><Obec><Id>529397</Id><StatId></StatId><Value>Bratislava - mestská časť Karlova Ves</Value><Obce></Obce></Obec><Psc>84104</Psc><Stat><Id>703</Id><Value>Slovenská republika</Value></Stat></Bydlisko><StatnaPrislusnost><Id>703</Id><Value>Slovenská republika</Value></StatnaPrislusnost><TypDokladu><Id></Id><Value></Value></TypDokladu><CisloDokladu></CisloDokladu><PostavenieKUV><APriameOvladaniePO>true</APriameOvladaniePO><A1HlasovaciePrava>true</A1HlasovaciePrava><A2ZakladneImanie>true</A2ZakladneImanie><A3PravoVymenovatRiadiaciOrgan>true</A3PravoVymenovatRiadiaciOrgan><A4InySposobOvladania>true</A4InySposobOvladania><A5PravoNaHospProspech>true</A5PravoNaHospProspech><A6KonanieVZhode>false</A6KonanieVZhode><BVrcholovyManazment>false</BVrcholovyManazment></PostavenieKUV></KonecniUzivateliaVyhod><ZakladneImanie><Suma>5000</Suma><Mena><Id>6</Id><Value>EUR</Value><Znacka>EUR</Znacka></Mena></ZakladneImanie><RozsahSplatenia><Suma>5000</Suma><Mena><Id>6</Id><Value>EUR</Value><Znacka>EUR</Znacka></Mena></RozsahSplatenia><SplynutieEnum>None</SplynutieEnum><PremenaPO><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa><PravnaFormaBris><Id></Id><Value></Value></PravnaFormaBris><slovZahrEnum>None</slovZahrEnum></PremenaPO><RozdelovanaPO><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa><PravnaFormaBris><Id></Id><Value></Value></PravnaFormaBris><slovZahrEnum>None</slovZahrEnum></RozdelovanaPO><OstatneNastupnickePO><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa><PravnaFormaBris><Id></Id><Value></Value></PravnaFormaBris><slovZahrEnum>None</slovZahrEnum></OstatneNastupnickePO><CezhranicnaZmenaPravnejFormyPO><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa><PravnaFormaBris><Id></Id><Value></Value></PravnaFormaBris><slovZahrEnum>None</slovZahrEnum></CezhranicnaZmenaPravnejFormyPO><Podpis><TitulPred></TitulPred><Meno></Meno><Priezvisko></Priezvisko><TitulZa></TitulZa></Podpis><DobaUrcita><Datum xsi:nil="true"></Datum><JeDobaUrcita>false</JeDobaUrcita></DobaUrcita></FUPS>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair)} ), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count
  end

  test 'sets recipient name' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Návrh na zápis xy s. r. o. do obchodného registra',
      uuid: SecureRandom.uuid,
      metadata: {
        message_type: 'ks_352538',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?mso-application progid="InfoPath.Document" versionProgid="InfoPath.Document.2"?><?mso-infoPath-file-attachment-present ?><?xml-stylesheet type="text/xsl" href="http://eformulare.justice.sk/schemasAndTransformations/FUPS.2023.08.21.xslt" ?><FUPS xmlns="http://www.justice.gov.sk/Forms20230821" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><IdentifikacneUdajeFormulara><Nazov></Nazov><IdentifikatorMFSR></IdentifikatorMFSR><Verzia>1.0.0.1181</Verzia><Popis>PSRO</Popis><NazovGaranta></NazovGaranta><PlatnostOd xsi:nil="true"></PlatnostOd><PlatnostDo xsi:nil="true"></PlatnostDo></IdentifikacneUdajeFormulara><InfoPathData><ID>b76962a3-256a-46b1-87bb-68deff0b03a4</ID><Message></Message><BinaryIn xsi:nil="true"></BinaryIn><BinaryOut xsi:nil="true"></BinaryOut><ValidationResult>0</ValidationResult><ShowWarnings>true</ShowWarnings></InfoPathData><ObchodnyRegister><OkresnySud>Mestský súd Bratislava III</OkresnySud><Ulica>Námestie Biely kríž</Ulica><Cislo>7</Cislo><Obec>Bratislava III</Obec><Psc>83607</Psc><Id>2</Id><Kod>B</Kod></ObchodnyRegister><ZapisatK xsi:nil="true"></ZapisatK><PrilohyKNavrhu><poradoveCislo>1</poradoveCislo><Nazov>Spoločenská zmluva alebo zakladateľská listina</Nazov></PrilohyKNavrhu><PrilohyKNavrhu><poradoveCislo>2</poradoveCislo><Nazov>Listina, ktorou sa preukazuje podnikateľské oprávnenie na vykonávanie činnosti, ktorá sa má do obchodného registra zapísať ako predmet podnikania</Nazov></PrilohyKNavrhu><PrilohyKNavrhu><poradoveCislo>3</poradoveCislo><Nazov>Písomné vyhlásenie správcu vkladu podľa osobitného zákona. (§ 60 ods. 4 Obchodného zákonníka)</Nazov></PrilohyKNavrhu><PrilohyKNavrhu><poradoveCislo>4</poradoveCislo><Nazov>Listina, ktorou sa preukazuje vlastnícke právo alebo užívacie právo k nehnuteľnosti alebo jej časti, ktoré užívanie nehnuteľnosti alebo jej časti ako sídla alebo miesta podnikania nevylučuje, alebo súhlas vlastníka nehnuteľnosti alebo jej časti so zápisom nehnuteľnosti alebo jej časti ako sídla alebo miesta podnikania do obchodného registra podľa osobitného predpisu. (§ 2 ods. 3 Obchodného zákonníka)</Nazov></PrilohyKNavrhu><PrilohyKNavrhu><poradoveCislo>5</poradoveCislo><Nazov>Písomné vyhlásenie zakladateľa, že nie je jediným spoločníkom vo viac ako dvoch spoločnostiach s ručením obmedzeným, ak spoločnosť založila jediná fyzická osoba</Nazov></PrilohyKNavrhu><PrilohyKNavrhu><poradoveCislo>6</poradoveCislo><Nazov>Písomné plnomocenstvo podľa § 5 ods. 3 zákona, ak návrh podáva osoba splnomocnená navrhovateľom</Nazov></PrilohyKNavrhu><Spolocnost>SSD test s. r. o.</Spolocnost><V>Bratislava</V><Dna>2024-12-05</Dna><Postou>true</Postou><Osobne>false</Osobne><NavrhovatelFO><Osoba><TitulPred>Ing.</TitulPred><Meno>Ján</Meno><Priezvisko>Suchal</Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo></RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Adresa><Ulica>Ulica X</Ulica><Cislo>1</Cislo><Obec><Id>529397</Id><StatId></StatId><Value>Bratislava - mestská časť Karlova Ves</Value><Obce></Obce></Obec><Psc>84104</Psc><Stat><Id>703</Id><Value>Slovenská republika</Value></Stat></Adresa></NavrhovatelFO><ObchodneMeno>SSD test s. r. o.</ObchodneMeno><Sidlo><Ulica>Staré grunty</Ulica><Cislo>18</Cislo><Obec><Id>529397</Id><StatId></StatId><Value>Bratislava - mestská časť Karlova Ves</Value><Obce></Obce></Obec><Psc>84104</Psc><Stat><Id>703</Id><Value>Slovenská republika</Value></Stat></Sidlo><Ico></Ico><PravnaForma><Id></Id><Value></Value></PravnaForma><PredmetPodnikania><PoradoveCislo>1</PoradoveCislo><Cinnost>Uskutočňovanie stavieb a ich zmien</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>2</PoradoveCislo><Cinnost>Vypracovanie dokumentácie a projektu jednoduchých stavieb, drobných stavieb a zmien týchto stavieb: stavebná časť</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>3</PoradoveCislo><Cinnost>Kúpa tovaru na účely jeho predaja konečnému spotrebiteľovi (maloobchod) alebo iným prevádzkovateľom živnosti (veľkoobchod)</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>4</PoradoveCislo><Cinnost>Prípravné práce k realizácii stavby</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>5</PoradoveCislo><Cinnost>Dokončovacie stavebné práce pri realizácii exteriérov a interiérov</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>6</PoradoveCislo><Cinnost>Prenájom, úschova a požičiavanie hnuteľných vecí</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>7</PoradoveCislo><Cinnost>Sprostredkovateľská činnosť v oblasti obchodu, služieb, výroby</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>8</PoradoveCislo><Cinnost>Verejné obstarávanie</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>9</PoradoveCislo><Cinnost>Počítačové služby a služby súvisiace s počítačovým spracovaním údajov</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>10</PoradoveCislo><Cinnost>Murárstvo</Cinnost></PredmetPodnikania><PredmetPodnikania><PoradoveCislo>11</PoradoveCislo><Cinnost>Výkon činnosti stavbyvedúceho</Cinnost></PredmetPodnikania><StatutarnyOrganFO><FunkciaClenaStatutarnehoOrganu><Id></Id><Value></Value></FunkciaClenaStatutarnehoOrganu><Funkcia></Funkcia><Osoba><TitulPred>Ing.</TitulPred><Meno>Ján</Meno><Priezvisko>Suchal</Priezvisko><TitulZa></TitulZa><DatumNarodenia>2000-01-01</DatumNarodenia><RodneCislo>000101/8727</RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Bydlisko><Ulica>Ulica X</Ulica><Cislo>1</Cislo><Obec><Id>529397</Id><StatId></StatId><Value>Bratislava - mestská časť Karlova Ves</Value><Obce></Obce></Obec><Psc>84104</Psc><Stat><Id>703</Id><Value>Slovenská republika</Value></Stat></Bydlisko><DenVznikuFunkcie xsi:nil="true"></DenVznikuFunkcie><DenSkonceniaFunkcie xsi:nil="true"></DenSkonceniaFunkcie></StatutarnyOrganFO><StatutarnyOrganSposobKonania>Konateľ koná v mene spoločnosti samostatne.</StatutarnyOrganSposobKonania><OrganizacnaZlozka><OrganizacnaZlozka><Oznacenie></Oznacenie><AdresaUmiestnenia><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></AdresaUmiestnenia><PredmetPodnikania><PoradoveCislo></PoradoveCislo><Cinnost></Cinnost></PredmetPodnikania><Veduci><FunkciaClenaStatutarnehoOrganu><Id></Id><Value></Value></FunkciaClenaStatutarnehoOrganu><Funkcia></Funkcia><Osoba><TitulPred></TitulPred><Meno></Meno><Priezvisko></Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo></RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Bydlisko><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Bydlisko><DenVznikuFunkcie xsi:nil="true"></DenVznikuFunkcie><DenSkonceniaFunkcie xsi:nil="true"></DenSkonceniaFunkcie></Veduci></OrganizacnaZlozka></OrganizacnaZlozka><Prokurista><FunkciaClenaStatutarnehoOrganu><Id></Id><Value></Value></FunkciaClenaStatutarnehoOrganu><Funkcia></Funkcia><Osoba><TitulPred></TitulPred><Meno></Meno><Priezvisko></Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo></RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Bydlisko><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Bydlisko><DenVznikuFunkcie xsi:nil="true"></DenVznikuFunkcie><DenSkonceniaFunkcie xsi:nil="true"></DenSkonceniaFunkcie></Prokurista><ProkuraSposobKonania></ProkuraSposobKonania><SpolocniciFO><Spolocnik><Osoba><TitulPred>Ing.</TitulPred><Meno>Ján</Meno><Priezvisko>Suchal</Priezvisko><TitulZa></TitulZa><DatumNarodenia>2000-01-01</DatumNarodenia><RodneCislo>000101/8727</RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Adresa><Ulica>Ulica X</Ulica><Cislo>1</Cislo><Obec><Id>529397</Id><StatId></StatId><Value>Bratislava - mestská časť Karlova Ves</Value><Obce></Obce></Obec><Psc>84104</Psc><Stat><Id>703</Id><Value>Slovenská republika</Value></Stat></Adresa></Spolocnik><Vklad><VyskaVkladu><Suma>5000</Suma><Mena><Id>6</Id><Value>EUR</Value><Znacka>EUR</Znacka></Mena><TypVkladu><Id>1</Id><Value>peňažný vklad</Value></TypVkladu></VyskaVkladu><RozsahSplatenia><Suma>5000</Suma><Mena><Id>6</Id><Value>EUR</Value><Znacka>EUR</Znacka></Mena></RozsahSplatenia></Vklad></SpolocniciFO><SpolocniciPO><Spolocnik><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa></Spolocnik><Vklad><VyskaVkladu><Suma xsi:nil="true"></Suma><Mena><Id></Id><Value></Value><Znacka></Znacka></Mena><TypVkladu><Id></Id><Value></Value></TypVkladu></VyskaVkladu><RozsahSplatenia><Suma xsi:nil="true"></Suma><Mena><Id></Id><Value></Value><Znacka></Znacka></Mena></RozsahSplatenia></Vklad></SpolocniciPO><Spoluvlastnictvo><SpolocnyObchodnyPodel><VyskaVkladu><Suma xsi:nil="true"></Suma><Mena><Id></Id><Value></Value><Znacka></Znacka></Mena><TypVkladu><Id></Id><Value></Value></TypVkladu></VyskaVkladu><RozsahSplatenia><Suma xsi:nil="true"></Suma><Mena><Id></Id><Value></Value><Znacka></Znacka></Mena></RozsahSplatenia></SpolocnyObchodnyPodel><SpolocnyZastupcaFO><Osoba><TitulPred></TitulPred><Meno></Meno><Priezvisko></Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo></RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa></SpolocnyZastupcaFO><SpolocnyZastupcaPO><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa></SpolocnyZastupcaPO><SpoluvlastnikFO><Osoba><TitulPred></TitulPred><Meno></Meno><Priezvisko></Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo></RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa></SpoluvlastnikFO><SpoluvlastnikPO><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa></SpoluvlastnikPO></Spoluvlastnictvo><DozornaRada><FunkciaClenaStatutarnehoOrganu><Id></Id><Value></Value></FunkciaClenaStatutarnehoOrganu><Funkcia></Funkcia><Osoba><TitulPred></TitulPred><Meno></Meno><Priezvisko></Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo></RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Bydlisko><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Bydlisko><DenVznikuFunkcie xsi:nil="true"></DenVznikuFunkcie><DenSkonceniaFunkcie xsi:nil="true"></DenSkonceniaFunkcie></DozornaRada><KonecniUzivateliaVyhod><Osoba><TitulPred>Ing.</TitulPred><Meno>Ján</Meno><Priezvisko>Suchal</Priezvisko><TitulZa></TitulZa><DatumNarodenia xsi:nil="true"></DatumNarodenia><RodneCislo>000101/8727</RodneCislo><TypInyIdentifikator><Id></Id><Value></Value><Znacka></Znacka></TypInyIdentifikator><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj></Osoba><Bydlisko><Ulica>Ulica X</Ulica><Cislo>1</Cislo><Obec><Id>529397</Id><StatId></StatId><Value>Bratislava - mestská časť Karlova Ves</Value><Obce></Obce></Obec><Psc>84104</Psc><Stat><Id>703</Id><Value>Slovenská republika</Value></Stat></Bydlisko><StatnaPrislusnost><Id>703</Id><Value>Slovenská republika</Value></StatnaPrislusnost><TypDokladu><Id></Id><Value></Value></TypDokladu><CisloDokladu></CisloDokladu><PostavenieKUV><APriameOvladaniePO>true</APriameOvladaniePO><A1HlasovaciePrava>true</A1HlasovaciePrava><A2ZakladneImanie>true</A2ZakladneImanie><A3PravoVymenovatRiadiaciOrgan>true</A3PravoVymenovatRiadiaciOrgan><A4InySposobOvladania>true</A4InySposobOvladania><A5PravoNaHospProspech>true</A5PravoNaHospProspech><A6KonanieVZhode>false</A6KonanieVZhode><BVrcholovyManazment>false</BVrcholovyManazment></PostavenieKUV></KonecniUzivateliaVyhod><ZakladneImanie><Suma>5000</Suma><Mena><Id>6</Id><Value>EUR</Value><Znacka>EUR</Znacka></Mena></ZakladneImanie><RozsahSplatenia><Suma>5000</Suma><Mena><Id>6</Id><Value>EUR</Value><Znacka>EUR</Znacka></Mena></RozsahSplatenia><SplynutieEnum>None</SplynutieEnum><PremenaPO><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa><PravnaFormaBris><Id></Id><Value></Value></PravnaFormaBris><slovZahrEnum>None</slovZahrEnum></PremenaPO><RozdelovanaPO><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa><PravnaFormaBris><Id></Id><Value></Value></PravnaFormaBris><slovZahrEnum>None</slovZahrEnum></RozdelovanaPO><OstatneNastupnickePO><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa><PravnaFormaBris><Id></Id><Value></Value></PravnaFormaBris><slovZahrEnum>None</slovZahrEnum></OstatneNastupnickePO><CezhranicnaZmenaPravnejFormyPO><ObchodneMeno></ObchodneMeno><Ico></Ico><InyIdentifikacnyUdaj></InyIdentifikacnyUdaj><Adresa><Ulica></Ulica><Cislo></Cislo><Obec><Id></Id><StatId></StatId><Value></Value><Obce></Obce></Obec><Psc></Psc><Stat><Id></Id><Value></Value></Stat></Adresa><PravnaFormaBris><Id></Id><Value></Value></PravnaFormaBris><slovZahrEnum>None</slovZahrEnum></CezhranicnaZmenaPravnejFormyPO><Podpis><TitulPred></TitulPred><Meno></Meno><Priezvisko></Priezvisko><TitulZa></TitulZa></Podpis><DobaUrcita><Datum xsi:nil="true"></Datum><JeDobaUrcita>false</JeDobaUrcita></DobaUrcita></FUPS>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair)} ), as: :json

    assert 'Test OVM identity 2', Message.last.recipient_name
  end

  test 'SignatureRestedTag is assigned from SignerGroup if object marked to_be_signed' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair)} ), as: :json

    assert_response :created
    assert @box.messages.last.objects.first.tags.include?(@tenant.signer_group.signature_requested_from_tag)
    assert @box.messages.last.thread.tags.include?(@tenant.signature_requested_tag!)
  end

  test 'can upload valid message with tags if they exist' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ],
      tags: ['Legal', 'Other']
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count

    assert Upvs::MessageDraft.last.tags.map(&:name).include?('Legal')
    assert Upvs::MessageDraft.last.tags.map(&:name).include?('Other')
  end

  test 'does not create message unless valid MessageDraft type' do
    message_params = {
      type: 'Vszp::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :bad_request

    json_response = JSON.parse(response.body)
    assert_equal "Disallowed message type: Vszp::MessageDraft", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless unique UUID in the box' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: @box.messages.first.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :conflict

    json_response = JSON.parse(response.body)
    assert_equal "Message with given UUID already exists", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless title present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal "Title can't be blank", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless no box for given sender URI present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'NonExistentURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal 'Invalid sender', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message if given sender URI for box in another tenant' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SolverMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal 'Invalid sender', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless recipient in white list' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/87654321'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal 'Recipient does not accept the form type', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless form type in white list' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Požiadanie o vyhotovenie kópie listiny uloženej v zbierke zákonom ustanovených listín obchodného registra',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: '00166073.MSSR_ORSR_Poziadanie_o_vyhotovenie_kopie_listiny_ulozenej_v_zbierke_listin.sk',
        posp_version: '1.53',
        message_type: 'ks_340702',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/87654321'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<ApplicationForDocumentCopy xmlns:e="http://schemas.gov.sk/form/00166073.MSSR_ORSR_Poziadanie_o_vyhotovenie_kopie_listiny_ulozenej_v_zbierke_listin.sk/1.53" xmlns="http://schemas.gov.sk/form/00166073.MSSR_ORSR_Poziadanie_o_vyhotovenie_kopie_listiny_ulozenej_v_zbierke_listin.sk/1.53">
          <MethodOfService>
            <Codelist>
              <CodelistCode>1000401</CodelistCode>
              <CodelistItem>
                <ItemCode>electronic</ItemCode>
                <ItemName Language="sk">v elektronickej podobe</ItemName>
              </CodelistItem>
            </Codelist>
          </MethodOfService>
          <DocumentsElectronicForm>
            <LegalPerson>
              <Codelist>
                <CodelistCode>MSSR-ORSR-LegalPerson</CodelistCode>
                <CodelistItem>
                  <ItemCode>53509285</ItemCode>
                  <ItemName Language="sk">J.J.Solar s. r. o. (IČO: 53509285, spisová značka: Sro/48243/T)</ItemName>
                  <Note Language="sk">eyJ2YWx1ZSI6IjUzNTA5Mjg1IiwidGV4dCI6IkouSi5Tb2xhciBzLiByLiBv
        LiAoScSMTzogNTM1MDkyODUsIHNwaXNvdsOhIHpuYcSNa2E6IFNyby80ODI0
        My9UKSIsInRpdGxlIjoiMTg4IEphbMWhb3bDqSIsImRlc2NyIjoie1wib2Rk
        aWVsXCI6MyxcInZsb3prYVwiOjQ4MjQzLFwic3VkXCI6N30iLCJuYW1lIjoi
        Si5KLlNvbGFyIHMuIHIuIG8uIChJxIxPOiA1MzUwOTI4NSwgc3Bpc292w6Eg
        em5hxI1rYTogU3JvLzQ4MjQzL1QpIiwiY29kZSI6IjUzNTA5Mjg1In0=
        </Note>
                </CodelistItem>
              </Codelist>
              <PersonData>
                <PhysicalAddress>
                  <AddressLine>188 Jalšové</AddressLine>
                </PhysicalAddress>
              </PersonData>
              <Document>
                <MakeCopy>true</MakeCopy>
                <Code>1</Code>
                <Name>Zakladateľská listina</Name>
              </Document>
              <Document>
                <MakeCopy>true</MakeCopy>
                <Code>3</Code>
                <Name>Vyhlásenie správcu vkladu</Name>
              </Document>
            </LegalPerson>
          </DocumentsElectronicForm>
          <Applicant>
            <PersonData>
              <ElectronicAddress>
                <InternetAddress>lucia.janikova@slovensko.digital</InternetAddress>
              </ElectronicAddress>
            </PersonData>
          </Applicant>
        </ApplicationForDocumentCopy>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal 'Recipient does not accept the form type', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless message type in white list' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Požiadanie o vyhotovenie kópie listiny uloženej v zbierke zákonom ustanovených listín obchodného registra',
      uuid: SecureRandom.uuid,      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'ks_340702',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/87654321'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal 'Recipient does not accept the form type', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless form is valid XML' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text & Poznamka</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }) , as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal 'Form XSD validation failed', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless form valid against XSD' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
  <poznamka>Poznamocka</poznamka>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal 'Form XSD validation failed', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless UUID present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)

    assert_equal "UUID can't be blank", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless Correlation ID present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal "Correlation ID can't be blank", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless Recipient URI present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal "No recipient URI", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless Message Type present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal "No message type", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless Reference ID in valid format' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        reference_id: '12345',
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal "Reference ID must be UUID", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless at least one message object present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        message_id: SecureRandom.uuid,
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: []
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal 'Message contains no objects', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless form object present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Attachment.xml',
          is_signed: false,
          mimetype: 'application/xml',
          object_type: 'ATTACHMENT',
          content: Base64.encode64('<Attachment><Content>Hello!</Content></Attachment>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal 'Message has to contain exactly one form object', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless exactly one form object present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        },
        {
          name: 'Attachment.xml',
          is_signed: false,
          mimetype: 'application/xml',
          object_type: 'FORM',
          content: Base64.encode64('<Attachment><Content>Hello!</Content></Attachment>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal 'Message has to contain exactly one form object', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'can upload valid message with multiples objects' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        },
        {
          name: 'Attachment.xml',
          is_signed: false,
          mimetype: 'application/xml',
          object_type: 'ATTACHMENT',
          content: Base64.encode64('<Attachment><Content>Hello!</Content></Attachment>')
        },
        {
          name: 'SignedAttachment.xml',
          is_signed: true,
          mimetype: 'application/xml',
          object_type: 'ATTACHMENT',
          content: Base64.encode64('<Attachment><Content>Hello!</Content></Attachment>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count

    assert Message.last.objects.last.tags.include?(tags(:ssd_signed_externally))
  end

  test 'can upload valid message with object tags if they exist' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>'),
          tags: ['Na podpis: Another user']
        }
      ],
      tags: ['Legal', 'Other']
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count
  end

  test 'can upload valid message with object SignatureRequestedFromTags if they exist' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>'),
          tags: ['Na podpis: Another user']
        }
      ],
      tags: ['Legal', 'Other']
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count

    assert Upvs::MessageDraft.last.objects.last.tags.map(&:name).include?('Na podpis: Another user')
  end

  test 'can upload valid message with object SignedByTags if they exist' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>'),
          tags: ['Podpísané: Another user']
        }
      ],
      tags: ['Legal', 'Other']
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :created
    assert_not_equal Message.count, @before_request_messages_count

    assert Upvs::MessageDraft.last.objects.last.tags.map(&:name).include?('Podpísané: Another user')
  end

  test 'does not create message unless object name present' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        },
        {
          is_signed: false,
          mimetype: 'application/xml',
          object_type: 'ATTACHMENT',
          content: Base64.encode64('<Attachment><Content>Hello!</Content></Attachment>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal "Objects is not valid, Name can't be blank", json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end
  
  test 'does not create message unless object mimetype in white list' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        },
        {
          name: 'Attachment.txt',
          is_signed: false,
          mimetype: 'text/plain',
          object_type: 'ATTACHMENT',
          content: Base64.encode64('<Attachment><Content>Hello!</Content></Attachment>')
        }
      ]
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert json_response['message'].start_with? 'Objects is not valid, MimeType of Attachment.txt object is disallowed, allowed mimetypes:'

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless tags with given names exist' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678'
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>')
        }
      ],
      tags: ['Special']
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal 'Tag with name Special does not exist', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end

  test 'does not create message unless user signature tags with given names exist' do
    message_params = {
      type: 'Upvs::MessageDraft',
      title: 'Všeobecná agenda',
      uuid: SecureRandom.uuid,
      metadata: {
        posp_id: 'App.GeneralAgenda',
        posp_version: '1.9',
        message_type: 'App.GeneralAgenda',
        correlation_id: SecureRandom.uuid,
        sender_uri: 'SSDMainURI',
        recipient_uri: 'ico://sk/12345678',
      },
      objects: [
        {
          name: 'Form.xml',
          is_signed: false,
          to_be_signed: true,
          mimetype: 'application/x-eform-xml',
          object_type: 'FORM',
          content: Base64.encode64('<?xml version="1.0" encoding="utf-8"?>
<GeneralAgenda xmlns="http://schemas.gov.sk/form/App.GeneralAgenda/1.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <subject>Všeobecný predmet</subject>
  <text>Všeobecný text</text>
</GeneralAgenda>'),
          tags: ['Podpisane']
        }
      ],
      tags: ['Legal', 'Other']
    }

    post '/api/messages/message_drafts', params: message_params.merge({ token: generate_api_token(sub: @tenant.id, key_pair: @key_pair) }), as: :json

    assert_response :unprocessable_content

    json_response = JSON.parse(response.body)
    assert_equal 'Signature tag with name Podpisane does not exist', json_response['message']

    assert_equal Message.count, @before_request_messages_count
  end
end
