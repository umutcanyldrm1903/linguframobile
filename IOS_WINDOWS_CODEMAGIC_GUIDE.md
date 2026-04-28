# iOS Publish From Windows (Codemagic)

Bu proje icin Windows kullanarak iOS build + TestFlight gonderimi Codemagic ile yapilir.

## 1) Apple tarafi (bir kez)

0. `Agreements, Tax, and Banking` / Apple Developer sozlesmeleri:
   - App Store Connect veya Apple Developer hesabinda bekleyen yeni sozlesme varsa imzala.
   - `A required agreement is missing or has expired` hatasi koddan degil, Apple hesabinda eksik/expired sozlesmeden gelir.
   - Bu islemi genelde Account Holder/Admin yetkili kisi yapabilir.
1. `Certificates, Identifiers & Profiles`:
   - App ID / Bundle ID: `com.lingufranca.app`
2. `App Store Connect > Apps`:
   - Uygulama kaydi olusturulmus olmali.
3. `App Store Connect > Users and Access > Keys`:
   - API Key olustur.
   - Bu 3 bilgi lazim:
     - `Issuer ID`
     - `Key ID`
     - `AuthKey_XXXX.p8` icerigi

## 2) Codemagic tarafi

Repoyu Codemagic'e bagla ve bu dosyadaki workflow'u kullan:
- Eger tum projeyi baglarsan: `codemagic.yaml` (repo root)
- Eger sadece mobil repoyu baglarsan: `mobile/lingufranca_mobile/codemagic.yaml`
- workflow name: `ios_testflight_windows`

### Environment variable/group

Codemagic'te `app_store_credentials` adinda bir group olustur ve sunlari ekle:

- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY_IDENTIFIER`  (Apple Key ID)
- `APP_STORE_CONNECT_PRIVATE_KEY` (p8 dosya icerigi, `-----BEGIN PRIVATE KEY-----` dahil)
- `CERTIFICATE_PRIVATE_KEY` (RSA 2048 private key, `-----BEGIN RSA PRIVATE KEY-----` dahil)

Not:
- `APP_STORE_CONNECT_PRIVATE_KEY` multi-line olarak kaydedilmeli.
- `CERTIFICATE_PRIVATE_KEY`, Apple `.p8` key degildir. Sertifika olusturmak icin ayri RSA private key olmalidir.
- Secret/Encrypted olarak isaretle.

## 3) Build calistirma

1. Codemagic > uygulama > `Start new build`
2. Workflow: `ios_testflight_windows`
3. Branch sec ve build baslat.

## 4) Build ciktilari

Basarili build sonunda:
- IPA artifact olusur.
- Build otomatik olarak App Store Connect'e yuklenir.
- `submit_to_testflight: true` oldugu icin TestFlight'e duser.

## 5) App Store Connect'te son adim

1. `TestFlight` sekmesinde build "Processing" bitmesini bekle.
2. Version ekraninda build'i sec.
3. App Privacy / Export compliance / metadata alanlarini doldur.
4. Review'a gonder.

## Troubleshooting

- Signing/provisioning hatasi:
  - `A required agreement is missing or has expired`: App Store Connect / Apple Developer sozlesmesini imzala, sonra build'i tekrar calistir.
  - Bundle ID'nin `com.lingufranca.app` oldugunu kontrol et.
  - API key degiskenlerinin adini birebir kontrol et.
  - `CERTIFICATE_PRIVATE_KEY is empty`: Codemagic environment group icine RSA private key ekle.
  - `Did not find any certificates`: Tek basina hata degildir; asil hata genelde bir sonraki satirda yazar.
- Build yukleniyor ama TestFlight'ta yok:
  - App Store Connect processing suresini bekle (genelde 10-30 dk).
