using System;
using UnityEngine;

namespace O2un.Data
{
    [Serializable]
    public sealed class PlayerData
    {
        public int HighScore = 0;
        public int CurrentChapter = 1;
        public int Gold = 0;
    }
}