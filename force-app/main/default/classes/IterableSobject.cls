public with sharing class IterableSobject implements Iterable<SObject> {
    private String query;

    public IterableSobject(String query) {
        this.query = query;
    }

    public Iterator<SObject> iterator() {
        return new SobjectIterator(query);
    }

    private class SobjectIterator implements Iterator<SObject> {
        private List<SObject> records;
        private Integer currentIndex;

        public SobjectIterator(String query) {
            this.records = Database.query(query);
            this.currentIndex = 0;
        }

        public Boolean hasNext() {
            return currentIndex < records.size();
        }

        public SObject next() {
            if (hasNext()) {
                return records.get(currentIndex++);
            } else {
                throw new NoSuchElementException('Iterator has no more elements.');
            }
        }

        public void remove() {
            throw new UnsupportedOperationException('Remove operation is not supported.');
        }
    }
}
