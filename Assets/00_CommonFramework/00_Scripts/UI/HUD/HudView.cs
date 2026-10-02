using UnityEngine;
using R3;
using UnityEngine.UI;
using TMPro;

namespace O2un.UI
{
    public sealed class HudView : MonoBehaviour
    {
        [SerializeField] private Image _progress;
        [SerializeField] private TMP_Text _text;
        
        public void Bind(HudVM vm)
        {
            vm.IsVisible.Subscribe(x => gameObject.SetActive(x)).AddTo(this);
            vm.CurrentHP.Subscribe(x =>
            {
                _progress.fillAmount = x;
                _text.SetText("{0}%", x * 100);
            }).AddTo(this);
        }
    }
}