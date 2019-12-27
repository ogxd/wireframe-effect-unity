using UnityEngine;
using UnityEngine.Rendering;

namespace Ogxd
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(Camera))]
    public class WireframeEffect : MonoBehaviour
    {
        public Color edgeColor = Color.black;
        public bool quadify = true;
        public float thickness = 0.5f;

        private Material effectMaterial;
        private Material EffectMaterial => effectMaterial ?? (effectMaterial = new Material(Shader.Find("Ogxd/Wireframe")));

        private Material blitMaterial;
        private Material BlitMaterial => blitMaterial ?? (blitMaterial = new Material(Shader.Find("Ogxd/Blit")));

        private Camera sourceCamera;
        private Camera SourceCamera => sourceCamera ?? (sourceCamera = GetComponent<Camera>());

        private RenderTexture effectTexture;
        private CommandBuffer effectCommands;

        private void RefreshCommandBuffer()
        {
            effectTexture = RenderTexture.GetTemporary(SourceCamera.pixelWidth, SourceCamera.pixelHeight, 16, UnityEngine.Experimental.Rendering.GraphicsFormat.B8G8R8A8_UNorm);

            if (effectCommands == null) {
                effectCommands = new CommandBuffer();
                effectCommands.name = "Wireframe Effect";
                sourceCamera.AddCommandBuffer(CameraEvent.AfterImageEffects, effectCommands);
            }

            effectCommands.Clear();
            effectCommands.SetRenderTarget(effectTexture);
            effectCommands.ClearRenderTarget(true, true, Color.clear);

            Renderer[] renderers = GameObject.FindObjectsOfType<Renderer>();
            for (int i = 0; i < renderers.Length; i++) {
                effectCommands.DrawRenderer(renderers[i], EffectMaterial);
            }

            effectCommands.Blit(effectTexture, sourceCamera.targetTexture, BlitMaterial);
        }

        public void OnPreRender()
        {
            // Updates render texture if viewport size changed
            if (effectTexture == null || effectTexture.width != sourceCamera.pixelWidth || effectTexture.height != sourceCamera.pixelHeight) {
                RefreshCommandBuffer();
            }
        }

        private void Start()
        {
            RefreshCommandBuffer();
        }

        private void OnGUI()
        {
            EffectMaterial.SetColor("_EdgeColor", edgeColor);
            EffectMaterial.SetFloat("_WireframeThickness", thickness);
            if (quadify)
                EffectMaterial.EnableKeyword("_QUADIFY");
            else
                EffectMaterial.DisableKeyword("_QUADIFY");
        }

        private void OnDisable()
        {
            RefreshCommandBuffer();
        }

        void OnDestroy()
        {
            if (effectCommands == null)
                return;

            sourceCamera.RemoveCommandBuffer(CameraEvent.AfterImageEffects, effectCommands);
            effectCommands.Clear();
        }
    }
}