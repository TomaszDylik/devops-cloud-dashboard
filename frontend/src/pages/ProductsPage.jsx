import { useEffect, useState } from 'react';

function ProductsPage() {
  const [items, setItems] = useState([]);
  const [name, setName] = useState('');
  const [price, setPrice] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const fetchItems = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await fetch('/api/items');
      if (!response.ok) {
        throw new Error('Failed to load products.');
      }
      const data = await response.json();
      setItems(Array.isArray(data) ? data : []);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchItems();
  }, []);

  const handleSubmit = async (event) => {
    event.preventDefault();
    setError('');

    if (!name.trim()) {
      setError('Product name is required.');
      return;
    }

    try {
      const response = await fetch('/api/items', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          name: name.trim(),
          price: price === '' ? undefined : Number(price)
        })
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Failed to add product.');
      }

      setName('');
      setPrice('');
      await fetchItems();
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <section>
      <h2>Products</h2>

      <form className="card" onSubmit={handleSubmit}>
        <label>
          Name
          <input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Laptop" />
        </label>
        <label>
          Price
          <input
            type="number"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            placeholder="e.g. 4999"
          />
        </label>
        <button type="submit">Add Product</button>
      </form>

      <div className="card">
        <button onClick={fetchItems} disabled={loading}>
          {loading ? 'Loading...' : 'Refresh'}
        </button>
        {error && <p className="error">{error}</p>}

        <ul className="items-list">
          {items.map((item) => (
            <li key={item.id}>
              <strong>{item.name}</strong>
              <span>Price: {item.price ?? 'n/a'}</span>
            </li>
          ))}
        </ul>

        {!items.length && !loading && <p>No products yet.</p>}
      </div>
    </section>
  );
}

export default ProductsPage;
