package com.memogame.app.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.HowToReg
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.memogame.app.core.DS
import com.memogame.app.core.DSText
import com.memogame.app.core.LocalDSColors
import com.memogame.app.core.pressableClickable
import kotlin.random.Random

private data class GateQuestion(val a: Int, val b: Int, val options: List<Int>)

private fun makeQuestion(): GateQuestion {
    val a = Random.nextInt(2, 10)
    val b = Random.nextInt(2, 10)
    val set = mutableSetOf(a + b)
    while (set.size < 3) set.add(Random.nextInt(4, 19))
    return GateQuestion(a, b, set.shuffled())
}

/**
 * Simple grown-up check (a small sum) shown before any purchase, as required
 * for children's apps.
 */
@Composable
fun ParentalGateDialog(onDismiss: () -> Unit, onPass: () -> Unit) {
    val ds = LocalDSColors.current
    var question by remember { mutableStateOf(makeQuestion()) }
    var wrong by remember { mutableStateOf(false) }

    Dialog(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .background(ds.surfaceElevated, RoundedCornerShape(DS.Radius.xl))
                .padding(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(22.dp)
        ) {
            Icon(
                Icons.Rounded.HowToReg,
                contentDescription = null,
                tint = ds.link,
                modifier = Modifier.size(44.dp)
            )

            Text(
                "Ask a grown-up",
                style = DSText.title.copy(fontSize = 24.sp),
                color = ds.textPrimary
            )

            Text(
                "What is ${question.a} + ${question.b}?",
                fontSize = 20.sp,
                fontWeight = FontWeight.SemiBold,
                color = ds.textSecondary
            )

            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                question.options.forEach { option ->
                    Box(
                        modifier = Modifier
                            .size(64.dp)
                            .pressableClickable {
                                if (option == question.a + question.b) {
                                    onPass()
                                } else {
                                    wrong = true
                                    question = makeQuestion()
                                }
                            }
                            .background(ds.primaryGradient, CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            "$option",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                }
            }

            if (wrong) {
                Text("Try again!", style = DSText.caption, color = ds.danger)
            }

            Text(
                "Cancel",
                style = DSText.body.copy(fontWeight = FontWeight.SemiBold),
                color = ds.link,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .pressableClickable { onDismiss() }
                    .padding(vertical = DS.Spacing.sm)
            )
        }
    }
}
