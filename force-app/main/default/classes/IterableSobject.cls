/**
 * Iterable implementation for SObject queries
 * Provides a simple iterator for SOQL query results
 * Note: This loads all records into memory at once. For large datasets,
 * consider using the Batch interface with CursorWrapper instead.
 */
public with sharing class IterableSobject implements Iterable<SObject> {
    private String query;

    /**
     * Create a new IterableSobject with a SOQL query
     * @param query The SOQL query to execute
     */
    public IterableSobject(String query) {
        if (String.isBlank(query)) {
            throw new AsyncException(AsyncException.ErrorType.INVALID_CONFIGURATION, 'Query cannot be blank');
        }
        this.query = query;
    }

    /**
     * Get an iterator for the query results
     * @return Iterator for SObjects
     */
    public Iterator<SObject> iterator() {
        return new SobjectIterator(query);
    }

    /**
     * Inner class that implements the Iterator interface
     */
    private class SobjectIterator implements Iterator<SObject> {
        private List<SObject> records;
        private Integer currentIndex;

        public SobjectIterator(String query) {
            try {
                this.records = Database.query(query);
                this.currentIndex = 0;
            } catch (Exception ex) {
                throw new AsyncException(AsyncException.ErrorType.CURSOR_ERROR, 'Failed to execute query for iterator: ' + ex.getMessage());
            }
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
