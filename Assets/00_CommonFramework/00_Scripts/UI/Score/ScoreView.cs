using R3;
using TMPro;
using UnityEngine;

namespace O2un.UI
{
    public sealed class ScoreView : MonoBehaviour
    {
        [SerializeField] private TMP_Text _text;

        public void Bind(ScoreVM vm)
        {
            vm.Score.Subscribe(x => _text.SetText("{0}", x)).AddTo(this);
        }
    }
}
