from meappy import waveform


def test_get_raw_data():
    med64_bin_path = ...  # TODO make test version of raw data
    data = waveform.get_raw_data(med64_bin_path)
    assert data.shape == (XXX, YYY)
