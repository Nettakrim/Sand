using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

[System.Serializable]
public class TetrisBag<T>
{
    [SerializeField] private T[] items;
    private bool[] ready;
    [System.NonSerialized] public int remaining;
    [SerializeField] private bool disallowRepeats;
    private int last;

    public TetrisBag(T[] items, bool disallowRepeats) {
        this.items = items;
        this.disallowRepeats = disallowRepeats;
        Init();
    }

    public void Init() {
        ready = new bool[items.Length];
        Reset();        
    }

    public void Reset() {
        remaining = ready.Length;
        for (int i = 0; i < remaining; i++) {
            ready[i] = true;
        }
    }

    public T Get() {
        if (remaining == 0) Reset();
        int countdown = Random.Range(0, remaining);
        remaining--;
        for (int i = 0; i < items.Length; i++) {
            if (ready[i]) {
                if (countdown == 0) {
                    if (disallowRepeats && last == i) {
                        return Get();
                    }
                    last = i;
                    ready[i] = false;
                    return items[i];
                }
                countdown--;
            }
        }
        Debug.LogWarning("Tetris Bag was not initialised properly");
        return GetIgnoringBag();
    }

    public T GetIgnoringBag() {
        return items[Random.Range(0,items.Length)];
    }
}