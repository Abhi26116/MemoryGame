package com.memogame.app.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Star
import androidx.compose.material.icons.rounded.StarOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.memogame.app.core.colorFromHex

@Composable
fun StarRating(stars: Int, max: Int = 3, size: Dp = 22.dp, modifier: Modifier = Modifier) {
    Row(modifier = modifier, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        repeat(max) { i ->
            Icon(
                if (i < stars) Icons.Rounded.Star else Icons.Rounded.StarOutline,
                contentDescription = null,
                tint = if (i < stars) colorFromHex("FFD60A") else Color.Gray.copy(alpha = 0.4f),
                modifier = Modifier.size(size)
            )
        }
    }
}
