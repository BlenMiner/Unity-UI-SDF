using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SignedDistanceFieldGraphic : Graphic
{
    [Header("Graphic")]

    [SerializeField] Texture m_texture;

    [SerializeField] float m_graphicBlur = 0f;

    [Header("Outline")]

    [SerializeField, Min(0f)] float m_outlineSize = 0f;

    [SerializeField] Color m_outlineColor = Color.black;

    [Header("Shadow")]

    [SerializeField, Min(0f)] float m_shadowSize = 0f;

    [SerializeField, Min(0f)] float m_shadowBlur = 0f;

    [SerializeField, Min(0f)] float m_shadowPower = 1f;

    [SerializeField] Color m_shadowColor = Color.black;
    

    private Material m_material;

    private float m_extraMargin => Mathf.Max(m_outlineSize, m_shadowSize);

    protected event Action<float, float> onMaterialUpdate;

    public override Texture mainTexture => m_texture;

    public override Material defaultMaterial
    {
        get
        {
            if (m_material == null)
                m_material = new Material(Shader.Find("Unlit/RectangleRenderer"));
            return m_material;
        }
    }

    private void UpdateShaderDimensions()
    {
        float width = rectTransform.rect.width;
        float height = rectTransform.rect.height;

        defaultMaterial.SetVector("_Size", new Vector2(
            width,
            height)
        );

        onMaterialUpdate?.Invoke(width, height);
    }

    public override void SetLayoutDirty()
    {
        base.SetLayoutDirty();

        float width = rectTransform.rect.width;
        float height = rectTransform.rect.height;

        UpdateShaderDimensions();
    }

    protected override void OnRectTransformDimensionsChange()
    {
        base.OnRectTransformDimensionsChange();

        UpdateShaderDimensions();
    }

    protected override void OnPopulateMesh(VertexHelper vh)
    {
        vh.Clear();

        float width = rectTransform.rect.width;
        float height = rectTransform.rect.height;

        Vector3 pivot = new Vector3(
            rectTransform.pivot.x * width,
            rectTransform.pivot.y * height, 0);

        UIVertex vertex = UIVertex.simpleVert;
        vertex.color = color;

        vertex.position = new Vector3(-m_extraMargin, -m_extraMargin) - pivot;
        vertex.uv0 = new Vector2(0, 0);
        vh.AddVert(vertex);

        vertex.position = new Vector3(-m_extraMargin, height + m_extraMargin) - pivot;
        vertex.uv0 = new Vector2(0, 1);
        vh.AddVert(vertex);

        vertex.position = new Vector3(width + m_extraMargin, height + m_extraMargin) - pivot;
        vertex.uv0 = new Vector2(1, 1);
        vh.AddVert(vertex);

        vertex.position = new Vector3(width + m_extraMargin, -m_extraMargin) - pivot;
        vertex.uv0 = new Vector2(1, 0);
        vh.AddVert(vertex);

        vh.AddTriangle(0, 1, 2);
        vh.AddTriangle(2, 3, 0);
    }

    public override void SetMaterialDirty()
    {
        base.SetMaterialDirty();

        float width = rectTransform.rect.width;
        float height = rectTransform.rect.height;

        UpdateShaderDimensions();

        defaultMaterial.SetTexture("_MainTex", mainTexture);
        defaultMaterial.SetFloat("_GraphicBlur", m_graphicBlur);

        defaultMaterial.SetFloat("_OutlineSize", m_outlineSize);
        defaultMaterial.SetColor("_OutlineColor", m_outlineColor);

        defaultMaterial.SetFloat("_ShadowSize", m_shadowSize);
        defaultMaterial.SetFloat("_ShadowBlur", m_shadowBlur);
        defaultMaterial.SetFloat("_ShadowPow", m_shadowPower);
        defaultMaterial.SetColor("_ShadowColor", m_shadowColor);

        defaultMaterial.SetFloat("_Padding", m_extraMargin);
    }
}
