# WorkManager (lo trae google_mobile_ads) crea su base de datos Room por
# reflexión con el constructor vacío de WorkDatabase_Impl. La regla de
# room-runtime 2.2.5 solo conserva la clase, y R8 en modo completo (por
# defecto desde AGP 8) borra el constructor: la app se cerraba al abrir.
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
