using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Game : MonoBehaviour
{
    [SerializeField] private ComputeShader computeShader;

    private int kernalInit;
    private int kernal3x3Start;
    private int kernalStep;

    private RenderTexture texA;
    private RenderTexture texB;

    [SerializeField] private Material material;

    private bool step = false;

    private int[] size = new int[2];

    private TetrisBag<int[]> offsets;

    private ComputeBuffer gateBuffer;

    private int[] shipping = new int[24];
    private ComputeBuffer shippingBuffer;

    void Start() {
        CreateRenderTexture(ref texA, 256, 256);
        CreateRenderTexture(ref texB, 256, 256);
        material.SetTexture("_TexA", texA);
        material.SetTexture("_TexB", texB);
        kernalInit = computeShader.FindKernel("CSInit");
        kernal3x3Start = computeShader.FindKernel("CS3x3Start");
        kernalStep = computeShader.FindKernel("CSStep");
        size = new int[]{texA.width, texA.height};

        offsets = new TetrisBag<int[]>(new int[][]{
            new int[]{0,0}, new int[]{1,0}, new int[]{2,0},
            new int[]{0,1}, new int[]{1,1}, new int[]{2,1},
            new int[]{0,2}, new int[]{1,2}, new int[]{2,2}
        }, true);

        Reset();
    }

    private void OnDestroy() {
        //try to prevent memory leaks
        Debug.Log("quitting");
        if (gateBuffer != null) gateBuffer.Release();
        if (shippingBuffer != null) shippingBuffer.Release();
        texA.Release();
        texB.Release();
    }

    void Reset() {
        step = false;

        if (gateBuffer != null) gateBuffer.Release();
        gateBuffer = new ComputeBuffer(4, sizeof(int));
        if (shippingBuffer != null) shippingBuffer.Release();
        shippingBuffer = new ComputeBuffer(24, sizeof(int));

        Start3x3();

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
        if (offsets.remaining == 0) {
            Start3x3();
        }

        SimulationStep(i, o, offsets.Get());

        material.SetFloat("_Step", step ? 1 : 0);
    }

    void Start3x3() {
        AsyncGPUReadback.Request(shippingBuffer, OnCompleteShippingReadBack);

        computeShader.SetBuffer(kernal3x3Start, "GateBuffer", gateBuffer);
        computeShader.SetBuffer(kernal3x3Start, "ShippingBuffer", shippingBuffer);
        computeShader.Dispatch(kernal3x3Start, 1, 1, 1);
    }

    void OnCompleteShippingReadBack(AsyncGPUReadbackRequest request) {
        if (shippingBuffer != null) {
            request.GetData<int>().CopyTo(shipping);
            //string s = "";
            //for (int i = 0; i < 24; i++) {
            //    s += shipping[i]+(i < 23 ? " " : "");
            //}
            //Debug.Log(s);
        }
    }

    void SimulationStep(RenderTexture i, RenderTexture o, int[] offset) {
        computeShader.SetTexture(kernalStep, "Input", i);
        computeShader.SetTexture(kernalStep, "Result", o);
        computeShader.SetInts("PosOffset", offset);
        computeShader.SetInts("Size", size);
        computeShader.SetBuffer(kernalStep, "GateBuffer", gateBuffer);
        computeShader.SetBuffer(kernalStep, "ShippingBuffer", shippingBuffer);

        computeShader.Dispatch(kernalStep, Mathf.CeilToInt(i.width / 3f)+1, Mathf.CeilToInt(i.height / 3f)+1, 1);
    }

    // https://forum.unity.com/threads/attempting-to-bind-texture-id-as-uav-the-texture-wasnt-created-with-the-uav-usage-flag-set.820512/
    void CreateRenderTexture(ref RenderTexture rt, int width, int height) {
        rt = new RenderTexture(width, height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
        rt.enableRandomWrite = true;
        rt.filterMode = FilterMode.Point;
        rt.Create();
    }
}
