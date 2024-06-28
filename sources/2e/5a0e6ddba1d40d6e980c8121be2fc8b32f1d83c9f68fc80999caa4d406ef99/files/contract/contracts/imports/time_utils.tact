fun extract_date(timestamp: Int): Int {
    return timestamp / (24 * 3600) * 24 * 3600;
}