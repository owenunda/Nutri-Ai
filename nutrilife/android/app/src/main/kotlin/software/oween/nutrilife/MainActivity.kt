package software.oween.nutrilife

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (y no FlutterActivity) porque enableEdgeToEdge() es
// de ComponentActivity. Con targetSdk 35, Android 15+ ya dibuja de borde a
// borde; esto hace que las versiones anteriores se vean igual.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
