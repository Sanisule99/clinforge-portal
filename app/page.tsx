// Root of results.integrishds.com with no token in the URL.
// Patients always arrive via /r/<token> from their SMS, so this is just a
// friendly signpost rather than an error.

export default function Home() {
  return (
    <>
      <div className="bar">
        <div className="brand">
          <div className="mark">L</div>
          <div className="txt">
            <div className="name">ClinForge</div>
            <div className="tag">Patient Results</div>
          </div>
        </div>
      </div>
      <div className="scroll">
        <div className="screen center-screen">
          <div className="big" style={{ fontSize: 40, marginBottom: 14 }}>
            &#128279;
          </div>
          <h1>Open your results from your message</h1>
          <p className="lede" style={{ marginTop: 12 }}>
            Please use the secure link sent to your phone by the laboratory to
            view your results. If you can&apos;t find it, contact the lab that
            took your sample.
          </p>
        </div>
      </div>
    </>
  );
}
