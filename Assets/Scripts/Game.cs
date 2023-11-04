using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Game : MonoBehaviour
{
    [SerializeField] private ComputeShader computeShader;

    private int kernalMain;
    private int kernalInit;

    private RenderTexture texA;
    private RenderTexture texB;

    [SerializeField] private Material material;

    private bool step = false;

    private int[] size = new int[2];

    private TetrisBag<int[]> offsets;

    void Start() {
        CreateRenderTexture(ref texA, 256, 256);
        CreateRenderTexture(ref texB, 256, 256);
        kernalMain = computeShader.FindKernel("CSMain");
        kernalInit = computeShader.FindKernel("CSInit");
        size = new int[]{texA.width, texA.height};

        offsets = new TetrisBag<int[]>(new int[][]{
            new int[]{0,0}, new int[]{1,0}, new int[]{2,0},
            new int[]{0,1}, new int[]{1,1}, new int[]{2,1},
            new int[]{0,2}, new int[]{1,2}, new int[]{2,2}
        }, true);

        Reset();
    }

    void Reset() {
        step = false;

        computeShader.SetTexture(kernalInit, "Input", texA);
        computeShader.SetTexture(kernalInit, "Result", texB);
        computeShader.SetInts("Size", size);
        computeShader.Dispatch(kernalInit, texA.width / 8, texA.height / 8, 1);
    }

    void Update() {
        if (Input.GetKeyDown(KeyCode.Space)) {
            Reset();
        }

        if (step) {
            step = false;
            Simulate(texA, texB);
        } else {
            step = true;
            Simulate(texB, texA);
        }
    }

    void Simulate(RenderTexture i, RenderTexture o) {
        SimulationStep(i, o, offsets.Get());

        material.SetTexture("_MainTex", o);
    }

    void SimulationStep(RenderTexture i, RenderTexture o, int[] offset) {
        computeShader.SetTexture(kernalMain, "Input", i);
        computeShader.SetTexture(kernalMain, "Result", o);
        computeShader.SetInts("PosOffset", offset);
        computeShader.SetInts("Size", size);

        computeShader.Dispatch(kernalMain, Mathf.CeilToInt(i.width / 3f)+1, Mathf.CeilToInt(i.height / 3f)+1, 1);
    }

    // https://forum.unity.com/threads/attempting-to-bind-texture-id-as-uav-the-texture-wasnt-created-with-the-uav-usage-flag-set.820512/
    void CreateRenderTexture(ref RenderTexture rt, int width, int height) {
        rt = new RenderTexture(width, height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
        rt.enableRandomWrite = true;
        rt.filterMode = FilterMode.Point;
        rt.Create();
    }
}
